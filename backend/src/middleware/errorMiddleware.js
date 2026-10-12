const mongoose = require("mongoose");
const { sendError } = require("../utils/apiResponse");

/**
 * Centralised error-handling middleware.
 * Must be registered AFTER all routes in server.js:
 *   app.use(errorMiddleware)
 *
 * Handles:
 *  - Mongoose ValidationError
 *  - Mongoose CastError (bad ObjectId)
 *  - Mongoose duplicate-key error (code 11000)
 *  - Custom { status, message } errors thrown from controllers
 *  - Generic unhandled errors
 */
const errorMiddleware = (err, req, res, next) => {
  // --- Mongoose Validation Error ---
  if (err.name === "ValidationError") {
    const errors = Object.values(err.errors).map((e) => e.message);
    return sendError(res, 400, "Validation failed", errors);
  }

  // --- Mongoose Bad ObjectId ---
  if (err.name === "CastError") {
    return sendError(res, 400, `Invalid value for field: ${err.path}`);
  }

  // --- Mongoose Duplicate Key ---
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    return sendError(res, 409, `A record with this ${field} already exists.`);
  }

  // --- Custom application error (thrown with { status, message }) ---
  if (err.status && err.message) {
    return sendError(res, err.status, err.message);
  }

  // --- JWT errors (if jwt.verify throws) ---
  if (err.name === "JsonWebTokenError" || err.name === "TokenExpiredError") {
    return sendError(res, 401, "Not authorized, token invalid or expired");
  }

  // --- Fallback ---
  console.error("[Error Middleware]", err);
  return sendError(res, 500, "Something went wrong on the server");
};

module.exports = errorMiddleware;
