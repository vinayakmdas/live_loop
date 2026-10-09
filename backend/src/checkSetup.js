require("dotenv").config();

const {
  generateAccessToken,
  generateRefreshToken,
  hashToken,
} = require("./utils/generateToken");
const jwt = require("jsonwebtoken");

// These two lines check the models load without errors
require("./models/User");
require("./models/RefreshToken");
console.log("✅ Models loaded");

// Check .env values exist
console.log("Access secret set:", !!process.env.JWT_ACCESS_SECRET);
console.log("Refresh secret set:", !!process.env.JWT_REFRESH_SECRET);
console.log("Access expiry:", process.env.JWT_ACCESS_EXPIRES_IN);
console.log("Refresh expiry:", process.env.JWT_REFRESH_EXPIRES_IN);

// Create and verify tokens
const accessToken = generateAccessToken("test-user-id");
const refreshToken = generateRefreshToken("test-user-id");

const decodedAccess = jwt.verify(accessToken, process.env.JWT_ACCESS_SECRET);
const decodedRefresh = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

console.log("✅ Access token works:", decodedAccess);
console.log("✅ Refresh token works:", decodedRefresh);
console.log("✅ Hash:", hashToken(refreshToken));