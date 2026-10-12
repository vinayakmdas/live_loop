const Meeting = require("../models/Meeting");
const { generateMeetingLink } = require("../utils/generateMeetingLink");

/**
 * Low-level database operations for meetings.
 * No business logic lives here — that belongs in the service layer.
 */

/** Create a new meeting document */
const createMeeting = async (data) => {
  return Meeting.create(data);
};

/** Find a meeting by its internal _id */
const findById = async (meetingId) => {
  return Meeting.findById(meetingId)
    .populate("createdBy", "name username email")
    .populate("members.user", "name username email");
};

/** Find a meeting by unique meeting link */
const findByLink = async (link) => {
  return Meeting.findOne({ meetingLink: link, status: "active" })
    .populate("createdBy", "name username email")
    .populate("members.user", "name username email");
};

/**
 * Find meetings where the user is the owner OR a member.
 * Supports cursor-based pagination via `page` / `limit` and optional category filter.
 */
const findUserMeetings = async (userId, { page = 1, limit = 20, category } = {}) => {
  const query = {
    $or: [{ createdBy: userId }, { "members.user": userId }],
    status: "active",
  };

  if (category) {
    query.category = category.toLowerCase();
  }

  const skip = (page - 1) * limit;

  const [meetings, total] = await Promise.all([
    Meeting.find(query)
      .populate("createdBy", "name username email")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Meeting.countDocuments(query),
  ]);

  return { meetings, total, page, limit };
};

/** Update allowed fields on a meeting */
const updateMeeting = async (meetingId, updates) => {
  return Meeting.findByIdAndUpdate(meetingId, { $set: updates }, { new: true, runValidators: true })
    .populate("createdBy", "name username email")
    .populate("members.user", "name username email");
};

/** Push a new member to a meeting */
const addMember = async (meetingId, memberEntry) => {
  return Meeting.findByIdAndUpdate(
    meetingId,
    { $push: { members: memberEntry } },
    { new: true }
  );
};

/** Pull a member from a meeting */
const removeMember = async (meetingId, userId) => {
  return Meeting.findByIdAndUpdate(
    meetingId,
    { $pull: { members: { user: userId } } },
    { new: true }
  );
};

/** Archive a meeting (soft delete) */
const archiveMeeting = async (meetingId) => {
  return Meeting.findByIdAndUpdate(meetingId, { $set: { status: "archived" } }, { new: true });
};

/** Hard delete a meeting */
const deleteMeeting = async (meetingId) => {
  return Meeting.findByIdAndDelete(meetingId);
};

module.exports = {
  createMeeting,
  findById,
  findByLink,
  findUserMeetings,
  updateMeeting,
  addMember,
  removeMember,
  archiveMeeting,
  deleteMeeting,
};
