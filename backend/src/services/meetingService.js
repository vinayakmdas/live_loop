const Meeting = require("../models/Meeting");
const meetingRepo = require("../repositories/meetingRepository");
const { generateMeetingLink } = require("../utils/generateMeetingLink");
const { generateJoinCode } = require("../utils/generateJoinCode");

/**
 * Business logic for all meeting operations.
 * Controllers call this layer; this layer calls the repository.
 */

/** ── Create a meeting ──────────────────────────────────────────────────── */
const createMeeting = async ({
  name,
  description,
  category,
  accessType = "public",
  meetingType = "instant",
  scheduledStartTime = null,
  password = null,
  userId,
}) => {
  const meetingLink = generateMeetingLink();
  let joinCode = null;
  let roomPassword = null;

  // For private meetings, use provided password or generate a unique 6-character code
  if (accessType === "private") {
    if (password && typeof password === "string" && password.trim()) {
      roomPassword = password.trim();
      joinCode = roomPassword.toUpperCase();
    } else {
      let isUnique = false;
      let attempts = 0;
      while (!isUnique && attempts < 5) {
        const code = generateJoinCode();
        const existing = await Meeting.findOne({
          $or: [{ joinCode: code }, { password: code }],
        });
        if (!existing) {
          joinCode = code;
          roomPassword = code;
          isUnique = true;
        }
        attempts++;
      }
      if (!joinCode) {
        joinCode = generateJoinCode();
        roomPassword = joinCode;
      }
    }
  }

  // If a scheduledStartTime is provided, meetingType is scheduled for later.
  // If not scheduled, it starts instantly.
  const effectiveMeetingType = scheduledStartTime ? "scheduled" : "instant";

  const meeting = await meetingRepo.createMeeting({
    name,
    description,
    category,
    accessType,
    password: roomPassword,
    joinCode,
    meetingType: effectiveMeetingType,
    scheduledStartTime,
    createdBy: userId,
    meetingLink,
    // Creator is automatically the first member with role "owner"
    members: [{ user: userId, role: "owner", joinedAt: new Date() }],
  });

  return meeting;
};

/** ── Get a meeting by ID — enforce access rules ───────────────────────── */
const getMeetingById = async (meetingId, userId) => {
  const meeting = await meetingRepo.findById(meetingId);

  if (!meeting || meeting.status === "archived") {
    const err = new Error("Meeting not found");
    err.status = 404;
    throw err;
  }

  // Invite-only: only members and owner may view
  if (
    meeting.accessType === "invite_only" &&
    !meeting.isMember(userId) &&
    !meeting.isOwner(userId)
  ) {
    const err = new Error("You do not have permission to view this meeting");
    err.status = 403;
    throw err;
  }

  return meeting;
};

/** ── List meetings the user owns or has joined ─────────────────────────── */
const getUserMeetings = async (userId, options) => {
  return meetingRepo.findUserMeetings(userId, options);
};

/** ── Update a meeting ───────────────────────────────────────────────────── */
const updateMeeting = async (meetingId, userId, updates) => {
  const meeting = await meetingRepo.findById(meetingId);

  if (!meeting || meeting.status === "archived") {
    const err = new Error("Meeting not found");
    err.status = 404;
    throw err;
  }

  // Only owner or moderator may update
  const membership = meeting.members.find(
    (m) => m.user._id.toString() === userId.toString()
  );
  const isOwnerOrMod =
    meeting.isOwner(userId) ||
    (membership && membership.role === "moderator");

  if (!isOwnerOrMod) {
    const err = new Error("You are not authorised to update this meeting");
    err.status = 403;
    throw err;
  }

  // Only permit safe fields
  const allowed = ["name", "description", "category", "accessType"];
  const safeUpdates = {};
  allowed.forEach((key) => {
    if (updates[key] !== undefined) safeUpdates[key] = updates[key];
  });

  return meetingRepo.updateMeeting(meetingId, safeUpdates);
};

/** ── Archive a meeting ─────────────────────────────────────────────────── */
const archiveMeeting = async (meetingId, userId) => {
  const meeting = await meetingRepo.findById(meetingId);

  if (!meeting || meeting.status === "archived") {
    const err = new Error("Meeting not found");
    err.status = 404;
    throw err;
  }

  if (!meeting.isOwner(userId)) {
    const err = new Error("Only the meeting owner can archive this meeting");
    err.status = 403;
    throw err;
  }

  return meetingRepo.archiveMeeting(meetingId);
};

/** ── Join a meeting via meeting link, meeting ID, or joinCode ─────────── */
const joinMeeting = async (userId, target) => {
  let meeting = null;
  const meetingId =
    typeof target === "object" && target !== null ? target.meetingId : null;
  const meetingLink =
    typeof target === "object" && target !== null
      ? target.meetingLink
      : typeof target === "string"
      ? target
      : null;
  const joinCode =
    typeof target === "object" && target !== null ? target.joinCode : null;
  const passcode =
    typeof target === "object" && target !== null
      ? target.passcode || target.code
      : null;

  if (meetingId) {
    meeting = await meetingRepo.findById(meetingId);
  } else if (meetingLink) {
    meeting = await meetingRepo.findByLink(meetingLink);
  } else if (joinCode) {
    meeting = await meetingRepo.findByJoinCode(joinCode);
  }

  if (!meeting || meeting.status === "archived") {
    const err = new Error("Invalid or expired meeting");
    err.status = 404;
    throw err;
  }

  const isOwner = meeting.isOwner(userId);
  const isMember = meeting.isMember(userId);

  // If the meeting is scheduled for a future time, enforce that it automatically
  // becomes available only at the scheduled start time.
  if (
    meeting.scheduledStartTime &&
    (meeting.meetingType === "scheduled" || meeting.meetingType === "later")
  ) {
    const startTime = new Date(meeting.scheduledStartTime);
    const now = new Date();
    if (now < startTime) {
      const formattedTime = startTime.toLocaleString();
      const err = new Error(
        `This meeting is scheduled for ${formattedTime} and will automatically become available at that time.`
      );
      err.status = 400;
      err.isScheduledFuture = true;
      err.scheduledStartTime = startTime;
      throw err;
    }
  }

  // Private meeting: creator & existing members join directly.
  // Attendees must provide the correct room password to join.
  if (meeting.accessType === "private") {
    if (!isOwner && !isMember) {
      const enteredPasscode =
        typeof passcode === "string" ? passcode.trim() : "";

      if (!enteredPasscode) {
        const err = new Error(
          "This room is private. Please enter the room password to join."
        );
        err.status = 403;
        err.requiresPasscode = true;
        throw err;
      }

      const expectedPassword = (
        meeting.password ||
        meeting.joinCode ||
        ""
      ).trim();

      const isMatch =
        expectedPassword &&
        (enteredPasscode.toLowerCase() === expectedPassword.toLowerCase() ||
          enteredPasscode === expectedPassword);

      if (!isMatch) {
        const err = new Error(
          "Invalid room password. Please verify the password and try again."
        );
        err.status = 403;
        err.requiresPasscode = true;
        throw err;
      }
    }
  } else if (meeting.accessType === "invite_only" && !isOwner) {
    const alreadyInvited = meeting.invitees.some(
      (i) =>
        i.user.toString() === userId.toString() &&
        (i.status === "pending" || i.status === "accepted")
    );

    if (!alreadyInvited && !isMember) {
      const err = new Error("This meeting is invite only");
      err.status = 403;
      throw err;
    }
  }

  // Already a member — idempotent
  if (isMember) {
    return meeting;
  }

  return meetingRepo.addMember(meeting._id, {
    user: userId,
    role: "member",
    joinedAt: new Date(),
  });
};

/** ── Search meetings by name (e.g. search private rooms) ───────────────── */
const searchMeetings = async ({ query = "", type = "private", userId = null }) => {
  return meetingRepo.searchMeetings({ query, type, userId });
};

/** ── Leave a meeting ───────────────────────────────────────────────────── */
const leaveMeeting = async (meetingId, userId) => {
  const meeting = await meetingRepo.findById(meetingId);

  if (!meeting || meeting.status === "archived") {
    const err = new Error("Meeting not found");
    err.status = 404;
    throw err;
  }

  // Owner cannot leave without transferring ownership or archiving
  if (meeting.isOwner(userId)) {
    const err = new Error(
      "You are the owner. Please archive the meeting or transfer ownership before leaving."
    );
    err.status = 400;
    throw err;
  }

  if (!meeting.isMember(userId)) {
    const err = new Error("You are not a member of this meeting");
    err.status = 400;
    throw err;
  }

  return meetingRepo.removeMember(meetingId, userId);
};

/** ── Delete a meeting ─────────────────────────────────────────────────── */
const deleteMeeting = async (meetingId, userId) => {
  const meeting = await meetingRepo.findById(meetingId);

  if (!meeting) {
    const err = new Error("Meeting not found");
    err.status = 404;
    throw err;
  }

  if (!meeting.isOwner(userId)) {
    const err = new Error("Only the meeting owner can delete this meeting");
    err.status = 403;
    throw err;
  }

  await meetingRepo.deleteMeeting(meetingId);
};

module.exports = {
  createMeeting,
  getMeetingById,
  getUserMeetings,
  searchMeetings,
  updateMeeting,
  archiveMeeting,
  joinMeeting,
  leaveMeeting,
  deleteMeeting,
};
