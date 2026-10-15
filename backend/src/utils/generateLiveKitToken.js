const { AccessToken } = require("livekit-server-sdk");

/**
 * Mask an API key for safe diagnostic logging (e.g. "APIabc...1234").
 */
const maskKey = (key) => {
  if (!key) return "<missing>";
  if (key.length <= 8) return `${key.substring(0, 2)}***`;
  return `${key.substring(0, 6)}...${key.substring(key.length - 4)}`;
};

/**
 * Check if LiveKit configuration is valid.
 * Returns an object with { valid, error, warning }.
 */
const checkLiveKitConfig = () => {
  const apiKey = (process.env.LIVEKIT_API_KEY || "").trim();
  const apiSecret = (process.env.LIVEKIT_API_SECRET || "").trim();
  const serverUrl = (process.env.LIVEKIT_URL || "").trim();

  if (!apiKey || !apiSecret) {
    return {
      valid: false,
      error:
        "LIVEKIT_API_KEY and LIVEKIT_API_SECRET must be set in backend/.env to generate video call tokens.",
      isPlaceholder: false,
    };
  }

  const isPlaceholder = apiKey === "devkey" || apiSecret === "devsecret";
  const isCloud = serverUrl.includes("livekit.cloud");

  let warning = null;
  if (isCloud && isPlaceholder) {
    warning =
      `[LiveKit Config Warning] LIVEKIT_URL is configured for LiveKit Cloud (${serverUrl}), ` +
      `but LIVEKIT_API_KEY is using the local placeholder 'devkey'. ` +
      `LiveKit Cloud requires real API credentials from your cloud.livekit.io project dashboard. ` +
      `Connecting with placeholder credentials will result in 'Invalid API key'.`;
  }

  return {
    valid: true,
    apiKey,
    apiSecret,
    serverUrl,
    isPlaceholder,
    isCloud,
    warning,
  };
};

/**
 * Generate a LiveKit participant access token with room join permissions.
 *
 * @param {Object} options
 * @param {string} options.roomName - Name of the room the participant is joining
 * @param {string} options.participantIdentity - Authenticated user's unique ID
 * @param {string} [options.participantName] - Display name for the participant
 * @param {string} [options.ttl="6h"] - Token time-to-live
 * @returns {Promise<string>} Signed JWT access token for LiveKit
 */
const generateLiveKitToken = async ({
  roomName,
  participantIdentity,
  participantName,
  ttl = "6h",
}) => {
  if (!roomName || !roomName.trim()) {
    throw new Error("Cannot generate LiveKit token: roomName is required.");
  }
  if (!participantIdentity || !String(participantIdentity).trim()) {
    throw new Error(
      "Cannot generate LiveKit token: authenticated participantIdentity is required."
    );
  }

  const config = checkLiveKitConfig();
  if (!config.valid) {
    console.error("[LiveKit Error]", config.error);
    throw new Error(config.error);
  }

  if (config.warning) {
    console.warn(config.warning);
  }

  const identity = String(participantIdentity).trim();
  const name = String(participantName || identity).trim();
  const cleanRoomName = String(roomName).trim();

  // Create token with participant identity, display name, and TTL
  const at = new AccessToken(config.apiKey, config.apiSecret, {
    identity,
    name,
    ttl,
  });

  // Grant video room join permissions
  // In livekit-server-sdk, canPublish: true automatically grants camera, microphone, and screen-sharing permissions.
  at.addGrant({
    roomJoin: true,
    room: cleanRoomName,
    canPublish: true,
    canSubscribe: true,
    canPublishData: true,
  });

  try {
    const jwt = await at.toJwt();

    // Safe diagnostic logging (never log secret or full JWT)
    console.log(
      `[LiveKit] Participant token generated successfully | ` +
        `Room: "${cleanRoomName}" | ` +
        `Identity: "${identity}" | ` +
        `API Key: ${maskKey(config.apiKey)} | ` +
        `Server: ${config.serverUrl || "wss://live-loop-wdcidnza.livekit.cloud"} | ` +
        `TTL: ${ttl} | ` +
        `TokenLength: ${jwt.length}`
    );

    return jwt;
  } catch (err) {
    console.error(
      `[LiveKit Token Generation Error] Failed to generate token for Room: "${cleanRoomName}", Identity: "${identity}":`,
      err
    );
    throw err;
  }
};

module.exports = {
  generateLiveKitToken,
  checkLiveKitConfig,
};
