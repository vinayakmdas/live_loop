const crypto = require("crypto");

/**
 * Generate a cryptographically secure, URL-safe meeting join token.
 * 32 random bytes → 64 hex characters.
 * Statistically collision-proof for any realistic meeting volume.
 *
 * @returns {string}
 */
const generateMeetingLink = () => {
  return crypto.randomBytes(32).toString("hex");
};

module.exports = { generateMeetingLink };
