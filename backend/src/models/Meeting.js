const mongoose = require("mongoose");

const CATEGORIES = ["project", "friends", "community", "team", "other"];
const ACCESS_TYPES = ["invite_only", "anyone_with_link"];

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
      default: "invite_only",
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
meetingSchema.index({ createdAt: -1 });

// ─── Instance helper: check if a user is a member ─────────────────────────
meetingSchema.methods.isMember = function (userId) {
  return this.members.some((m) => m.user.toString() === userId.toString());
};

// ─── Instance helper: check if a user is the owner ────────────────────────
meetingSchema.methods.isOwner = function (userId) {
  return this.createdBy.toString() === userId.toString();
};

const Meeting = mongoose.model("Meeting", meetingSchema);

module.exports = Meeting;
module.exports.CATEGORIES = CATEGORIES;
module.exports.ACCESS_TYPES = ACCESS_TYPES;
