const { Server } = require("socket.io");

/**
 * In-memory store of recent messages for active meeting rooms.
 * Maps roomId -> Array of ChatMessage objects (capped at 100 per room).
 */
const roomMessages = new Map();

/**
 * Initialize Socket.IO with HTTP server and configure chat events.
 *
 * @param {import("http").Server} server
 * @returns {Server}
 */
const initSocket = (server) => {
  const io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
    },
    pingTimeout: 30000,
    pingInterval: 15000,
  });

  io.on("connection", (socket) => {
    console.log(`[Socket.IO] Client connected: ${socket.id}`);

    // ── Handle joining a meeting room chat ──────────────────────────────────
    socket.on("join_room", (rawPayload) => {
      let payload = rawPayload;
      if (typeof rawPayload === "string") {
        try {
          payload = JSON.parse(rawPayload);
        } catch (_) {
          payload = {};
        }
      }
      const { roomId, userId, userName } = payload || {};
      if (!roomId) {
        return socket.emit("error", { message: "roomId is required to join chat." });
      }

      const cleanRoomId = String(roomId).trim();
      const cleanUserId = String(userId || "anonymous").trim();
      const cleanUserName = String(userName || "Participant").trim();

      socket.join(cleanRoomId);
      socket.data = {
        roomId: cleanRoomId,
        userId: cleanUserId,
        userName: cleanUserName,
      };

      console.log(
        `[Socket.IO] User "${cleanUserName}" (${cleanUserId}) joined room "${cleanRoomId}" [Socket: ${socket.id}]`
      );

      // Send recent history of the room to the newly joined client
      const history = roomMessages.get(cleanRoomId) || [];
      socket.emit("room_history", history);

      // Notify other participants in the room
      socket.to(cleanRoomId).emit("user_joined", {
        userId: cleanUserId,
        userName: cleanUserName,
        timestamp: new Date().toISOString(),
      });
    });

    // ── Handle sending a message ───────────────────────────────────────────
    socket.on("send_message", (rawPayload) => {
      let payload = rawPayload;
      if (typeof rawPayload === "string") {
        try {
          payload = JSON.parse(rawPayload);
        } catch (_) {
          payload = {};
        }
      }
      const { id, roomId, text, senderId, senderName, timestamp } = payload || {};
      const targetRoom = String(roomId || (socket.data && socket.data.roomId) || "").trim();
      const cleanText = typeof text === "string" ? text.trim() : "";

      if (!targetRoom) {
        return socket.emit("error", { message: "No room specified for message." });
      }
      if (!cleanText) {
        return; // Ignore empty messages
      }

      // Ensure socket is joined to target room in case join_room packet was missed
      socket.join(targetRoom);

      const message = {
        id: id ? String(id).trim() : `${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
        roomId: targetRoom,
        senderId: String(senderId || (socket.data && socket.data.userId) || "anonymous").trim(),
        senderName: String(senderName || (socket.data && socket.data.userName) || "Participant").trim(),
        text: cleanText,
        timestamp: timestamp || new Date().toISOString(),
        isSystem: false,
      };

      // Store in memory (bounded to last 100 messages)
      if (!roomMessages.has(targetRoom)) {
        roomMessages.set(targetRoom, []);
      }
      const history = roomMessages.get(targetRoom);
      history.push(message);
      if (history.length > 100) {
        history.shift();
      }

      console.log(
        `[Socket.IO] Room "${targetRoom}" message from "${message.senderName}": ${message.text.substring(0, 40)}`
      );

      // Broadcast to EVERYONE in the room (including sender)
      io.to(targetRoom).emit("receive_message", message);
    });

    // ── Handle typing indicator ────────────────────────────────────────────
    socket.on("typing", (rawPayload) => {
      let payload = rawPayload;
      if (typeof rawPayload === "string") {
        try {
          payload = JSON.parse(rawPayload);
        } catch (_) {
          payload = {};
        }
      }
      const { roomId, isTyping } = payload || {};
      const targetRoom = String(roomId || (socket.data && socket.data.roomId) || "").trim();
      if (!targetRoom) return;

      socket.to(targetRoom).emit("user_typing", {
        userId: socket.data && socket.data.userId,
        userName: (socket.data && socket.data.userName) || "Someone",
        isTyping: Boolean(isTyping),
      });
    });

    // ── Handle leaving room ────────────────────────────────────────────────
    socket.on("leave_room", ({ roomId }) => {
      const targetRoom = String(roomId || socket.data.roomId || "").trim();
      if (targetRoom) {
        socket.leave(targetRoom);
        socket.to(targetRoom).emit("user_left", {
          userId: socket.data.userId,
          userName: socket.data.userName,
          timestamp: new Date().toISOString(),
        });
        console.log(`[Socket.IO] User "${socket.data.userName}" left room "${targetRoom}"`);
      }
    });

    // ── Handle disconnect ──────────────────────────────────────────────────
    socket.on("disconnect", (reason) => {
      console.log(`[Socket.IO] Client disconnected: ${socket.id} (${reason})`);
      if (socket.data && socket.data.roomId) {
        socket.to(socket.data.roomId).emit("user_left", {
          userId: socket.data.userId,
          userName: socket.data.userName,
          timestamp: new Date().toISOString(),
        });
      }
    });
  });

  return io;
};

module.exports = {
  initSocket,
};
