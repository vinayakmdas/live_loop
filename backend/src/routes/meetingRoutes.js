const express = require("express");
const { protect } = require("../middleware/authMiddleware");
const { validateObjectId } = require("../middleware/validateMiddleware");
const {
  validateCreateMeeting,
  validateUpdateMeeting,
} = require("../validators/meetingValidator");
const {
  createMeeting,
  getMyMeetings,
  getMeeting,
  updateMeeting,
  archiveMeeting,
  joinMeeting,
  leaveMeeting,
  deleteMeeting,
} = require("../controllers/meetingController");

const router = express.Router();

// All meeting routes are protected
router.use(protect);

// ── /api/meetings ──────────────────────────────────────────────────────────
router.post("/", validateCreateMeeting, createMeeting);
router.get("/", getMyMeetings);

// ── /api/meetings/join  (must come before /:meetingId to avoid param clash) ─
router.post("/join", joinMeeting);

// ── /api/meetings/:meetingId ───────────────────────────────────────────────
router.get("/:meetingId", validateObjectId("meetingId"), getMeeting);
router.patch(
  "/:meetingId",
  validateObjectId("meetingId"),
  validateUpdateMeeting,
  updateMeeting
);
router.patch(
  "/:meetingId/archive",
  validateObjectId("meetingId"),
  archiveMeeting
);
router.post(
  "/:meetingId/leave",
  validateObjectId("meetingId"),
  leaveMeeting
);
router.delete("/:meetingId", validateObjectId("meetingId"), deleteMeeting);

module.exports = router;
