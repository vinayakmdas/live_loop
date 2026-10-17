const meetingService = require("../services/meetingService");
const { sendSuccess, sendError } = require("../utils/apiResponse");
const { generateLiveKitToken } = require("../utils/generateLiveKitToken");

/**
 * Serialize a meeting document into the safe shape returned by every endpoint.
 * Never exposes password, refresh tokens, or internal hashes.
 * Only owners and members can see the private joinCode.
 */
const serializeMeeting = (meeting, currentUserId = null) => {
  const isOwner =
    currentUserId &&
    meeting.createdBy &&
    (meeting.createdBy._id?.toString() === currentUserId.toString() ||
      meeting.createdBy.toString() === currentUserId.toString());

  const isMember =
    currentUserId &&
    Array.isArray(meeting.members) &&
    meeting.members.some(
      (m) =>
        (m.user?._id?.toString() || m.user?.toString()) ===
        currentUserId.toString()
    );

  const canSeeCode = isOwner || isMember;
  const now = new Date();
  const isScheduledFuture =
    (meeting.meetingType === "scheduled" || meeting.meetingType === "later") &&
    meeting.scheduledStartTime &&
    new Date(meeting.scheduledStartTime) > now;
  const isAvailable = !isScheduledFuture;

  return {
    id: meeting._id,
    name: meeting.name,
    description: meeting.description,
    category: meeting.category,
    accessType: meeting.accessType,
    isPrivate: meeting.accessType === "private",
    isPublic: meeting.accessType === "public",
    joinCode: canSeeCode ? meeting.joinCode || meeting.password || null : null,
    password: canSeeCode ? meeting.password || meeting.joinCode || null : null,
    hasPassword: meeting.accessType === "private",
    isAvailable,
    meetingType: meeting.meetingType || "instant",
    scheduledStartTime: meeting.scheduledStartTime || null,
    meetingLink: meeting.meetingLink,
    status: meeting.status,
    createdBy: meeting.createdBy
      ? {
          id: meeting.createdBy._id || meeting.createdBy,
          name: meeting.createdBy.name,
          username: meeting.createdBy.username,
        }
      : null,
    memberCount: meeting.members ? meeting.members.length : 0,
    memberInitials: Array.isArray(meeting.members)
      ? meeting.members
          .map((m) =>
            m.user && m.user.name
              ? m.user.name.trim().charAt(0).toUpperCase()
              : null
          )
          .filter(Boolean)
      : [],
    createdAt: meeting.createdAt,
    updatedAt: meeting.updatedAt,
  };
};

// ── POST /api/meetings ─────────────────────────────────────────────────────
const createMeeting = async (req, res, next) => {
  try {
    const {
      name,
      description,
      category,
      accessType,
      meetingType,
      scheduledStartTime,
      password,
      joinCode,
    } = req.body;
    const userId = req.user.id;

    const meeting = await meetingService.createMeeting({
      name,
      description,
      category,
      accessType,
      meetingType,
      scheduledStartTime,
      password: password || joinCode || null,
      userId,
    });

    return sendSuccess(res, 201, "Meeting created successfully", {
      meeting: serializeMeeting(meeting, userId),
    });
  } catch (err) {
    next(err);
  }
};

// ── GET /api/meetings ──────────────────────────────────────────────────────
// Returns the public meeting list visible to everyone. Private rooms do NOT appear.
const getMyMeetings = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
    const category = req.query.category || null;
    const scope = req.query.scope || null;

    const { meetings, total } = await meetingService.getUserMeetings(userId, {
      page,
      limit,
      category,
      scope,
    });

    return sendSuccess(res, 200, "Meetings retrieved successfully", {
      meetings: meetings.map((m) => serializeMeeting(m, userId)),
      pagination: { total, page, limit, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

// ── GET /api/meetings/search ──────────────────────────────────────────────
// Search private rooms by name (e.g. "Maths Class")
const searchMeetings = async (req, res, next) => {
  try {
    const query = req.query.q || req.query.name || req.query.query || "";
    const type = req.query.type || "private";
    const userId = req.user.id;

    const meetings = await meetingService.searchMeetings({
      query,
      type,
      userId,
    });

    return sendSuccess(res, 200, "Search results retrieved successfully", {
      meetings: meetings.map((m) => serializeMeeting(m, userId)),
    });
  } catch (err) {
    next(err);
  }
};

// ── GET /api/meetings/:meetingId ───────────────────────────────────────────
const getMeeting = async (req, res, next) => {
  try {
    const meeting = await meetingService.getMeetingById(
      req.params.meetingId,
      req.user.id
    );
    return sendSuccess(res, 200, "Meeting retrieved successfully", {
      meeting: serializeMeeting(meeting, req.user.id),
    });
  } catch (err) {
    next(err);
  }
};

// ── PATCH /api/meetings/:meetingId ─────────────────────────────────────────
const updateMeeting = async (req, res, next) => {
  try {
    const updated = await meetingService.updateMeeting(
      req.params.meetingId,
      req.user.id,
      req.body
    );
    return sendSuccess(res, 200, "Meeting updated successfully", {
      meeting: serializeMeeting(updated, req.user.id),
    });
  } catch (err) {
    next(err);
  }
};

// ── PATCH /api/meetings/:meetingId/archive ─────────────────────────────────
const archiveMeeting = async (req, res, next) => {
  try {
    await meetingService.archiveMeeting(req.params.meetingId, req.user.id);
    return sendSuccess(res, 200, "Meeting archived successfully");
  } catch (err) {
    next(err);
  }
};

// ── POST /api/meetings/join or /api/meetings/:meetingId/join ───────────────
const joinMeeting = async (req, res, next) => {
  try {
    const {
      meetingLink,
      meetingId,
      joinCode,
      passcode,
      password,
      roomName: requestedRoomName,
    } = req.body || {};
    const queryRoomName = req.query ? req.query.roomName : null;
    const queryPasscode = req.query
      ? req.query.passcode || req.query.password || req.query.joinCode
      : null;
    const effectivePasscode = passcode || password || queryPasscode;
    const customRoom = (requestedRoomName || queryRoomName || "").trim();
    const targetMeetingId = req.params.meetingId || meetingId;

    let meeting;
    if (meetingLink || targetMeetingId || joinCode) {
      meeting = await meetingService.joinMeeting(req.user.id, {
        meetingLink:
          typeof meetingLink === "string" ? meetingLink.trim() : null,
        meetingId: targetMeetingId,
        joinCode: typeof joinCode === "string" ? joinCode.trim() : null,
        passcode:
          typeof effectivePasscode === "string"
            ? effectivePasscode.trim()
            : null,
      });
    } else if (customRoom) {
      const Meeting = require("../models/Meeting");
      let foundMeeting = await Meeting.findOne({
        $or: [
          { name: customRoom },
          { roomIdentifier: customRoom },
          { meetingLink: customRoom },
        ],
        status: "active",
      }).sort({ createdAt: -1 });

      if (!foundMeeting) {
        foundMeeting = await meetingService.createMeeting({
          name: customRoom,
          description: `Live room: ${customRoom}`,
          category: "community",
          accessType: "public",
          meetingType: "instant",
          userId: req.user.id,
        });
      } else {
        foundMeeting = await meetingService.joinMeeting(req.user.id, {
          meetingId: foundMeeting._id,
          passcode:
            typeof effectivePasscode === "string"
              ? effectivePasscode.trim()
              : null,
        });
      }
      meeting = foundMeeting;
    } else {
      const Meeting = require("../models/Meeting");
      let activeMeeting = await Meeting.findOne({
        status: "active",
        meetingType: "instant",
      }).sort({ createdAt: -1 });

      if (!activeMeeting) {
        activeMeeting = await meetingService.createMeeting({
          name: "Live Loop Main Room",
          description: "Weekly community meetup",
          category: "community",
          accessType: "public",
          meetingType: "instant",
          userId: req.user.id,
        });
      } else {
        activeMeeting = await meetingService.joinMeeting(req.user.id, {
          meetingId: activeMeeting._id,
        });
      }
      meeting = activeMeeting;
    }

    // Determine the exact room name to use for BOTH the token grant and connection
    const effectiveRoomName =
      customRoom ||
      meeting.name ||
      meeting.roomIdentifier ||
      meeting.meetingLink ||
      meeting._id.toString();

    // Generate a valid LiveKit participant token.
    // NEVER fall back to application login JWT — they have completely different
    // signatures and schemas, which will cause 'Invalid API key' on LiveKit Cloud.
    const livekitToken = await generateLiveKitToken({
      roomName: effectiveRoomName,
      participantIdentity: req.user.id.toString(),
      participantName: req.user.name || req.user.username || "Participant",
      metadata: JSON.stringify({
        profileImage: req.user.profileImage || null,
        name: req.user.name || req.user.username || "Participant",
        userId: req.user.id.toString(),
      }),
      ttl: "6h",
    });

    const serverUrl =
      process.env.LIVEKIT_URL || "wss://live-loop-wdcidnza.livekit.cloud";

    return sendSuccess(res, 200, "Joined meeting successfully", {
      meeting: serializeMeeting(meeting, req.user.id),
      token: livekitToken,
      roomName: effectiveRoomName,
      serverUrl,
    });
  } catch (err) {
    if (err.requiresPasscode) {
      return sendError(res, 403, err.message, [
        { code: "PASSCODE_REQUIRED", requiresPasscode: true },
      ]);
    }
    next(err);
  }
};

// ── POST /api/meetings/:meetingId/leave ────────────────────────────────────
const leaveMeeting = async (req, res, next) => {
  try {
    await meetingService.leaveMeeting(req.params.meetingId, req.user.id);
    return sendSuccess(res, 200, "You have left the meeting");
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/meetings/:meetingId ────────────────────────────────────────
const deleteMeeting = async (req, res, next) => {
  try {
    await meetingService.deleteMeeting(req.params.meetingId, req.user.id);
    return sendSuccess(res, 200, "Meeting deleted successfully");
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createMeeting,
  getMyMeetings,
  searchMeetings,
  getMeeting,
  updateMeeting,
  archiveMeeting,
  joinMeeting,
  leaveMeeting,
  deleteMeeting,
};
