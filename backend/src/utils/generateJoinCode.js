const crypto = require("crypto");

/**
 * Generate a unique, user-friendly 6-character meeting code.
 * Uses 32 clean uppercase letters and digits (excludes confusing characters: 0, O, 1, I).
 * Examples: '7B8KZ9', '4T2NWX', '9V3MPL'
 *
 * @returns {string}
 */
const CODE_CHARS = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";

const generateJoinCode = () => {
  const bytes = crypto.randomBytes(6);
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += CODE_CHARS[bytes[i] % CODE_CHARS.length];
  }
  return code;
};

module.exports = { generateJoinCode };
