const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const http = require("http");

dotenv.config();

const connectDatabase = require("./src/config/database");
const authRoutes = require("./src/routes/authRoutes");
const meetingRoutes = require("./src/routes/meetingRoutes");
const errorMiddleware = require("./src/middleware/errorMiddleware");

const app = express();
app.use(cors());
app.use(express.json());
app.use("/api/auth", authRoutes);
app.use("/api/meetings", meetingRoutes);
app.use(errorMiddleware);

const TEST_PORT = 5005;

function request(options, body = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, data: parsed });
        } catch {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on("error", reject);
    if (body) {
      req.write(typeof body === "string" ? body : JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log("=== Running Fresh Express + Mongoose Authentication & Token Refresh Tests ===");

  await connectDatabase();

  const server = await new Promise((resolve) => {
    const s = app.listen(TEST_PORT, "127.0.0.1", () => resolve(s));
  });

  try {
    const randomSuffix = Date.now();
    const testUser = {
      name: "Auth Test User",
      username: `authtest_${randomSuffix}`,
      email: `authtest_${randomSuffix}@example.com`,
      password: "Password123!",
    };

    // 1. Register
    console.log("\n[Step 1] Registering test user:", testUser.email);
    const regRes = await request(
      {
        hostname: "127.0.0.1",
        port: TEST_PORT,
        path: "/api/auth/register",
        method: "POST",
        headers: { "Content-Type": "application/json" },
      },
      testUser
    );

    console.log("Register response status:", regRes.status);
    if (regRes.status !== 201) {
      throw new Error("Registration failed: " + JSON.stringify(regRes.data));
    }
    const accessToken1 = regRes.data.data.accessToken;
    const refreshToken1 = regRes.data.data.refreshToken;
    console.log("✅ Received accessToken1:", accessToken1.substring(0, 25) + "...");
    console.log("✅ Received refreshToken1:", refreshToken1.substring(0, 25) + "...");

    // 2. Call protected endpoint with accessToken1
    console.log("\n[Step 2] Accessing /api/meetings with valid accessToken1...");
    const meetingsRes = await request({
      hostname: "127.0.0.1",
      port: TEST_PORT,
      path: "/api/meetings",
      method: "GET",
      headers: {
        Authorization: `Bearer ${accessToken1}`,
        "Content-Type": "application/json",
      },
    });
    console.log("Meetings response status:", meetingsRes.status);
    if (meetingsRes.status !== 200) {
      throw new Error("Failed to get meetings: " + JSON.stringify(meetingsRes.data));
    }
    console.log("✅ Protected endpoint returned 200 OK!");

    // 3. Call protected endpoint with invalid/expired access token
    console.log("\n[Step 3] Accessing /api/meetings with an expired/invalid token...");
    const invalidRes = await request({
      hostname: "127.0.0.1",
      port: TEST_PORT,
      path: "/api/meetings",
      method: "GET",
      headers: {
        Authorization: "Bearer invalid_expired_token_12345",
        "Content-Type": "application/json",
      },
    });
    console.log("Expired token response status:", invalidRes.status);
    if (invalidRes.status !== 401) {
      throw new Error("Expected 401 for expired token, got: " + invalidRes.status);
    }
    console.log("✅ Correctly rejected with 401 Unauthorized:", invalidRes.data.message);

    // 4. Refresh token to obtain new access and refresh tokens
    console.log("\n[Step 4] Refreshing token via POST /api/auth/refresh...");
    const refreshRes1 = await request(
      {
        hostname: "127.0.0.1",
        port: TEST_PORT,
        path: "/api/auth/refresh",
        method: "POST",
        headers: { "Content-Type": "application/json" },
      },
      { refreshToken: refreshToken1 }
    );
    console.log("Refresh response status:", refreshRes1.status);
    if (refreshRes1.status !== 200) {
      throw new Error("Refresh failed: " + JSON.stringify(refreshRes1.data));
    }
    const accessToken2 = refreshRes1.data.data.accessToken;
    const refreshToken2 = refreshRes1.data.data.refreshToken;
    console.log("✅ Successfully refreshed! Received new accessToken2:", accessToken2.substring(0, 25) + "...");
    console.log("✅ Received rotated refreshToken2:", refreshToken2.substring(0, 25) + "...");

    // 5. Test token rotation: old refreshToken1 should now be rejected!
    console.log("\n[Step 5] Attempting to reuse old refreshToken1 (should fail with 401)...");
    const reuseRes = await request(
      {
        hostname: "127.0.0.1",
        port: TEST_PORT,
        path: "/api/auth/refresh",
        method: "POST",
        headers: { "Content-Type": "application/json" },
      },
      { refreshToken: refreshToken1 }
    );
    console.log("Old token reuse status:", reuseRes.status);
    if (reuseRes.status !== 401) {
      throw new Error("Expected 401 for reused old refresh token, got: " + reuseRes.status);
    }
    console.log("✅ Old refresh token correctly rejected with 401:", reuseRes.data.message);

    // 6. Test that accessToken2 works on protected endpoint
    console.log("\n[Step 6] Accessing /api/meetings with newly refreshed accessToken2...");
    const meetingsRes2 = await request({
      hostname: "127.0.0.1",
      port: TEST_PORT,
      path: "/api/meetings",
      method: "GET",
      headers: {
        Authorization: `Bearer ${accessToken2}`,
        "Content-Type": "application/json",
      },
    });
    console.log("Meetings response status with accessToken2:", meetingsRes2.status);
    if (meetingsRes2.status !== 200) {
      throw new Error("Failed to get meetings with new token: " + JSON.stringify(meetingsRes2.data));
    }
    console.log("✅ Newly refreshed access token works seamlessly!");

    // 7. Test Logout: revoking refreshToken2
    console.log("\n[Step 7] Calling POST /api/auth/logout to revoke refreshToken2...");
    const logoutRes = await request(
      {
        hostname: "127.0.0.1",
        port: TEST_PORT,
        path: "/api/auth/logout",
        method: "POST",
        headers: { "Content-Type": "application/json" },
      },
      { refreshToken: refreshToken2 }
    );
    console.log("Logout response status:", logoutRes.status);
    if (logoutRes.status !== 200) {
      throw new Error("Logout failed: " + JSON.stringify(logoutRes.data));
    }
    console.log("✅ Logged out successfully!");

    // 8. Test refresh after logout: should fail with 401
    console.log("\n[Step 8] Attempting refresh after logout (should fail with 401)...");
    const afterLogoutRefresh = await request(
      {
        hostname: "127.0.0.1",
        port: TEST_PORT,
        path: "/api/auth/refresh",
        method: "POST",
        headers: { "Content-Type": "application/json" },
      },
      { refreshToken: refreshToken2 }
    );
    console.log("After logout refresh status:", afterLogoutRefresh.status);
    if (afterLogoutRefresh.status !== 401) {
      throw new Error("Expected 401 after logout, got: " + afterLogoutRefresh.status);
    }
    console.log("✅ Revoked refresh token correctly rejected with 401:", afterLogoutRefresh.data.message);

    console.log("\n🎉 ALL 8 INTEGRATION TESTS PASSED PERFECTLY! 🎉\n");
  } finally {
    server.close();
    process.exit(0);
  }
}

runTests().catch((err) => {
  console.error("❌ Test failed:", err);
  process.exit(1);
});
