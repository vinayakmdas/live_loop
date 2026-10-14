const meetingService = require("../services/meetingService");
const { sendSuccess, sendError } = require("../utils/apiResponse");
const { generateLiveKitToken } = require("../utils/generateLiveKitToken");

/**
 * Serialize a meeting document into the safe shape returned by every endpoint.
 * Never exposes password, refresh tokens, or internal hashes.
 */
const serializeMeeting = (meeting) => ({
  id: meeting._id,
  name: meeting.name,
  description: meeting.description,
  category: meeting.category,
  accessType: meeting.accessType,
  meetingType: meeting.meetingType || "instant",
  scheduledStartTime: meeting.scheduledStartTime || null,
  meetingLink: meeting.meetingLink,
  status: meeting.status,
  createdBy: meeting.createdBy
    ? {
        id: meeting.createdBy._id,
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
});

// ── POST /api/meetings ─────────────────────────────────────────────────────
const createMeeting = async (req, res, next) => {
  try {
    const { name, description, category, accessType, meetingType, scheduledStartTime } = req.body;
    const userId = req.user.id;

    const meeting = await meetingService.createMeeting({
      name,
      description,
      category,
      accessType,
      meetingType,
      scheduledStartTime,
      userId,
    });

    return sendSuccess(res, 201, "Meeting created successfully", {
      meeting: serializeMeeting(meeting),
    });
  } catch (err) {
    next(err);
  }
};

// ── GET /api/meetings ──────────────────────────────────────────────────────
const getMyMeetings = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
    const category = req.query.category || null;

    const { meetings, total } = await meetingService.getUserMeetings(userId, {
      page,
      limit,
      category,
    });

    return sendSuccess(res, 200, "Meetings retrieved successfully", {
      meetings: meetings.map(serializeMeeting),
      pagination: { total, page, limit, pages: Math.ceil(total / limit) },
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
      meeting: serializeMeeting(meeting),
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
      meeting: serializeMeeting(updated),
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
    const { meetingLink, meetingId, roomName: requestedRoomName } = req.body || {};
    const queryRoomName = req.query ? req.query.roomName : null;
    const customRoom = (requestedRoomName || queryRoomName || "").trim();
    const targetMeetingId = req.params.meetingId || meetingId;

    let meeting;
    if (meetingLink || targetMeetingId) {
      meeting = await meetingService.joinMeeting(req.user.id, {
        meetingLink: typeof meetingLink === "string" ? meetingLink.trim() : null,
        meetingId: targetMeetingId,
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
          accessType: "anyone_with_link",
          meetingType: "instant",
          userId: req.user.id,
        });
      } else {
        foundMeeting = await meetingService.joinMeeting(req.user.id, {
          meetingId: foundMeeting._id,
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
          accessType: "anyone_with_link",
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
      ttl: "6h",
    });

    const serverUrl =
      process.env.LIVEKIT_URL || "wss://live-loop-wdcidnza.livekit.cloud";

    return sendSuccess(res, 200, "Joined meeting successfully", {
      meeting: serializeMeeting(meeting),
      token: livekitToken,
      roomName: effectiveRoomName,
      serverUrl,
    });
  } catch (err) {
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
  getMeeting,
  updateMeeting,
  archiveMeeting,
  joinMeeting,
  leaveMeeting,
  deleteMeeting,
};
