const mongoose = require("mongoose");
const { sendError } = require("../utils/apiResponse");

/**
 * Validate that a route param or body field is a valid MongoDB ObjectId.
 * Usage:  router.get("/:meetingId", validateObjectId("meetingId"), handler)
 *
 * @param {string} paramName  - The req.params key to validate
 * @returns {import('express').RequestHandler}
 */
const validateObjectId = (paramName) => (req, res, next) => {
  if (!mongoose.Types.ObjectId.isValid(req.params[paramName])) {
    return sendError(res, 400, `Invalid ${paramName} format`);
  }
  next();
};

module.exports = { validateObjectId };
