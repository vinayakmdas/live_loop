const { CATEGORIES, ACCESS_TYPES, MEETING_TYPES } = require("../models/Meeting");
const { sendError } = require("../utils/apiResponse");

/**
 * Validate the request body for POST /api/meetings (create meeting).
 * Trims strings, checks lengths, and enforces allowed enum values.
 */
const validateCreateMeeting = (req, res, next) => {
  const errors = [];

  const name = typeof req.body.name === "string" ? req.body.name.trim() : "";
  const description =
    typeof req.body.description === "string" ? req.body.description.trim() : "";
  const category =
    typeof req.body.category === "string"
      ? req.body.category.trim().toLowerCase()
      : "";
  const accessType =
    typeof req.body.accessType === "string" && req.body.accessType.trim()
      ? req.body.accessType.trim().toLowerCase()
      : "public";
  const rawPassword =
    typeof req.body.password === "string"
      ? req.body.password.trim()
      : typeof req.body.joinCode === "string"
      ? req.body.joinCode.trim()
      : "";

  let scheduledStartTime = null;
  const rawStartTime =
    req.body.scheduledStartTime ||
    req.body.scheduledDate ||
    req.body.startTime;
  if (rawStartTime) {
    const parsedDate = new Date(rawStartTime);
    if (isNaN(parsedDate.getTime())) {
      errors.push("Invalid scheduled start time");
    } else {
      scheduledStartTime = parsedDate;
    }
  }

  // If user scheduled for later with a date/time, meetingType is scheduled.
  // If no future schedule was chosen, meeting starts instantly.
  const rawType = req.body.meetingType || req.body.scheduleType;
  let meetingType = scheduledStartTime ? "scheduled" : "instant";
  if (rawType === "scheduled" && !scheduledStartTime) {
    meetingType = "instant";
  }

  if (!name) {
    errors.push("Meeting name is required");
  } else if (name.length > 100) {
    errors.push("Meeting name cannot exceed 100 characters");
  }

  if (description.length > 500) {
    errors.push("Description cannot exceed 500 characters");
  }

  if (!category) {
    errors.push("Category is required");
  } else if (!CATEGORIES.includes(category)) {
    errors.push(
      `Category must be one of: ${CATEGORIES.join(", ")}`
    );
  }

  if (!ACCESS_TYPES.includes(accessType)) {
    errors.push(
      `Access type must be one of: ${ACCESS_TYPES.join(", ")}`
    );
  }

  if (rawPassword.length > 50) {
    errors.push("Password cannot exceed 50 characters");
  }

  if (errors.length > 0) {
    return sendError(res, 400, errors[0], errors);
  }

  // Sanitise onto req.body so controller receives clean data
  req.body.name = name;
  req.body.description = description;
  req.body.category = category;
  req.body.accessType = accessType;
  req.body.password = rawPassword || null;
  req.body.joinCode = rawPassword || null;
  req.body.meetingType = meetingType;
  req.body.scheduledStartTime = scheduledStartTime;

  next();
};

/**
 * Validate the request body for PATCH /api/meetings/:meetingId (update meeting).
 * All fields optional but individually validated if present.
 */
const validateUpdateMeeting = (req, res, next) => {
  const errors = [];

  if (req.body.name !== undefined) {
    const name =
      typeof req.body.name === "string" ? req.body.name.trim() : "";
    if (!name) {
      errors.push("Meeting name cannot be empty");
    } else if (name.length > 100) {
      errors.push("Meeting name cannot exceed 100 characters");
    } else {
      req.body.name = name;
    }
  }

  if (req.body.description !== undefined) {
    const description =
      typeof req.body.description === "string"
        ? req.body.description.trim()
        : "";
    if (description.length > 500) {
      errors.push("Description cannot exceed 500 characters");
    } else {
      req.body.description = description;
    }
  }

  if (req.body.category !== undefined) {
    const category =
      typeof req.body.category === "string"
        ? req.body.category.trim().toLowerCase()
        : "";
    if (!CATEGORIES.includes(category)) {
      errors.push(`Category must be one of: ${CATEGORIES.join(", ")}`);
    } else {
      req.body.category = category;
    }
  }

  if (req.body.accessType !== undefined) {
    const accessType =
      typeof req.body.accessType === "string"
        ? req.body.accessType.trim()
        : "";
    if (!ACCESS_TYPES.includes(accessType)) {
      errors.push(
        `Access type must be one of: ${ACCESS_TYPES.join(", ")}`
      );
    } else {
      req.body.accessType = accessType;
    }
  }

  if (errors.length > 0) {
    return sendError(res, 400, errors[0], errors);
  }

  next();
};

module.exports = { validateCreateMeeting, validateUpdateMeeting };
