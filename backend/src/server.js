const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");

const connectDatabase = require("./config/database");
const authRoutes = require("./routes/authRoutes");
const meetingRoutes = require("./routes/meetingRoutes");
const errorMiddleware = require("./middleware/errorMiddleware");
const { checkLiveKitConfig } = require("./utils/generateLiveKitToken");

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ── Health check ───────────────────────────────────────────────────────────
app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "Live Loop API is healthy",
    timestamp: new Date().toISOString(),
  });
});

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Live Loop backend is running",
  });
});

// ── Routes ─────────────────────────────────────────────────────────────────
app.use("/api/auth", authRoutes);
app.use("/api/meetings", meetingRoutes);

// ── 404 handler ───────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route not found" });
});

// ── Global error handler (must be last) ───────────────────────────────────
app.use(errorMiddleware);

const http = require("http");
const { initSocket } = require("./socket/chatSocket");

const server = http.createServer(app);
const io = initSocket(server);

const PORT = process.env.PORT || 5001;

const startServer = async () => {
  await connectDatabase();

  // Validate LiveKit configuration safely
  const lkConfig = checkLiveKitConfig();
  if (lkConfig.warning) {
    console.warn(lkConfig.warning);
  } else if (!lkConfig.valid) {
    console.warn(`[LiveKit Notice] ${lkConfig.error}`);
  } else {
    console.log(`[LiveKit] Config loaded: ${lkConfig.serverUrl} (key prefix: ${lkConfig.apiKey.substring(0, 4)}...)`);
  }

  server.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Socket.IO chat server initialized`);
    console.log(`Health: http://localhost:${PORT}/api/health`);
  });
};

startServer();