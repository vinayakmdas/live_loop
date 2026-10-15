const mongoose = require("mongoose");

const CATEGORIES = ["project", "friends", "community", "team", "other"];
const ACCESS_TYPES = ["public", "private", "invite_only", "anyone_with_link"];
const MEETING_TYPES = ["instant", "scheduled", "later"];

// ─── Member sub-document ───────────────────────────────────────────────────
// Role-based membership supports future permission layers (host, moderator, etc.)
const memberSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    role: {
      type: String,
      enum: ["owner", "moderator", "member"],
      default: "member",
    },
    joinedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

// ─── Invitee sub-document ──────────────────────────────────────────────────
// Tracks pending invitations. Status lets us differentiate accepted vs declined.
const inviteeSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    status: {
      type: String,
      enum: ["pending", "accepted", "declined"],
      default: "pending",
    },
    invitedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

// ─── Meeting schema ────────────────────────────────────────────────────────
const meetingSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Meeting name is required"],
      trim: true,
      maxlength: [100, "Meeting name cannot exceed 100 characters"],
    },

    description: {
      type: String,
      trim: true,
      maxlength: [500, "Description cannot exceed 500 characters"],
      default: "",
    },

    category: {
      type: String,
      required: [true, "Category is required"],
      enum: {
        values: CATEGORIES,
        message: "Category must be one of: " + CATEGORIES.join(", "),
      },
      lowercase: true,
    },

    accessType: {
      type: String,
      required: [true, "Access type is required"],
      enum: {
        values: ACCESS_TYPES,
        message: "Access type must be one of: " + ACCESS_TYPES.join(", "),
      },
      default: "public",
    },

    // Unique code / password required to join private meetings
    password: {
      type: String,
      default: null,
      trim: true,
    },

    // Retained for backwards compatibility with existing clients/data
    joinCode: {
      type: String,
      default: null,
      trim: true,
    },

    // Meeting timing configuration: instant vs scheduled for later
    meetingType: {
      type: String,
      enum: {
        values: MEETING_TYPES,
        message: "Meeting type must be one of: " + MEETING_TYPES.join(", "),
      },
      default: "instant",
    },

    scheduledStartTime: {
      type: Date,
      default: null,
    },

    // Creator reference — never expose password or sensitive fields
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    // Membership list (includes the owner)
    members: {
      type: [memberSchema],
      default: [],
    },

    // Pending invitations
    invitees: {
      type: [inviteeSchema],
      default: [],
    },

    // Cryptographically generated unique join link token
    meetingLink: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },

    // Future hook for WebRTC / meeting SDK room identifiers
    roomIdentifier: {
      type: String,
      default: null,
    },

    status: {
      type: String,
      enum: ["active", "archived"],
      default: "active",
    },
  },
  {
    timestamps: true, // adds createdAt and updatedAt automatically
  }
);

// ─── Indexes for common query patterns ────────────────────────────────────
meetingSchema.index({ createdBy: 1, status: 1 });
meetingSchema.index({ "members.user": 1, status: 1 });
meetingSchema.index({ category: 1, status: 1 });
meetingSchema.index({ accessType: 1, status: 1 });
meetingSchema.index({ accessType: 1, name: 1, status: 1 });
meetingSchema.index({ joinCode: 1 }, { sparse: true });
meetingSchema.index({ createdAt: -1 });

// ─── Instance helper: check if a user is a member ─────────────────────────
meetingSchema.methods.isMember = function (userId) {
  if (!userId || !Array.isArray(this.members)) return false;
  const targetId = userId.toString();
  return this.members.some((m) => {
    if (!m || !m.user) return false;
    const memberId = m.user._id ? m.user._id.toString() : m.user.toString();
    return memberId === targetId;
  });
};

// ─── Instance helper: check if a user is the owner ────────────────────────
meetingSchema.methods.isOwner = function (userId) {
  if (!userId || !this.createdBy) return false;
  const ownerId = this.createdBy._id
    ? this.createdBy._id.toString()
    : this.createdBy.toString();
  return ownerId === userId.toString();
};

const Meeting = mongoose.model("Meeting", meetingSchema);

module.exports = Meeting;
module.exports.CATEGORIES = CATEGORIES;
module.exports.ACCESS_TYPES = ACCESS_TYPES;
module.exports.MEETING_TYPES = MEETING_TYPES;
