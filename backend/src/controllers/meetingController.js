const meetingService = require("../services/meetingService");
const { sendSuccess, sendError } = require("../utils/apiResponse");

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
  createdAt: meeting.createdAt,
  updatedAt: meeting.updatedAt,
});

// ── POST /api/meetings ─────────────────────────────────────────────────────
const createMeeting = async (req, res, next) => {
  try {
    const { name, description, category, accessType } = req.body;
    const userId = req.user.id;

    const meeting = await meetingService.createMeeting({
      name,
      description,
      category,
      accessType,
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

// ── POST /api/meetings/join ────────────────────────────────────────────────
const joinMeeting = async (req, res, next) => {
  try {
    const { meetingLink } = req.body;

    if (!meetingLink || typeof meetingLink !== "string") {
      return sendError(res, 400, "Meeting link is required");
    }

    const meeting = await meetingService.joinMeeting(
      req.user.id,
      meetingLink.trim()
    );

    return sendSuccess(res, 200, "Joined meeting successfully", {
      meeting: serializeMeeting(meeting),
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
