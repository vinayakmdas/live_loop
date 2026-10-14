const meetingRepo = require("../repositories/meetingRepository");
const { generateMeetingLink } = require("../utils/generateMeetingLink");

/**
 * Business logic for all meeting operations.
 * Controllers call this layer; this layer calls the repository.
 */

/** ── Create a meeting ──────────────────────────────────────────────────── */
const createMeeting = async ({
  name,
  description,
  category,
  accessType,
  meetingType = "instant",
  scheduledStartTime = null,
  userId,
}) => {
  const meetingLink = generateMeetingLink();

  const meeting = await meetingRepo.createMeeting({
    name,
    description,
    category,
    accessType,
    meetingType,
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

  // Invite-only: only members may view
  if (meeting.accessType === "invite_only" && !meeting.isMember(userId)) {
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

/** ── Join a meeting via meeting link or meeting ID ─────────────────────── */
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

  if (meetingId) {
    meeting = await meetingRepo.findById(meetingId);
  } else if (meetingLink) {
    meeting = await meetingRepo.findByLink(meetingLink);
  }

  if (!meeting || meeting.status === "archived") {
    const err = new Error("Invalid or expired meeting");
    err.status = 404;
    throw err;
  }

  // Invite-only: must be invited (member or invitee with pending status) or owner
  if (meeting.accessType === "invite_only" && !meeting.isOwner(userId)) {
    const alreadyInvited = meeting.invitees.some(
      (i) =>
        i.user.toString() === userId.toString() &&
        (i.status === "pending" || i.status === "accepted")
    );
    const alreadyMember = meeting.isMember(userId);

    if (!alreadyInvited && !alreadyMember) {
      const err = new Error("This meeting is invite only");
      err.status = 403;
      throw err;
    }
  }

  // Already a member — idempotent
  if (meeting.isMember(userId)) {
    return meeting;
  }

  return meetingRepo.addMember(meeting._id, {
    user: userId,
    role: "member",
    joinedAt: new Date(),
  });
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
  updateMeeting,
  archiveMeeting,
  joinMeeting,
  leaveMeeting,
  deleteMeeting,
};
