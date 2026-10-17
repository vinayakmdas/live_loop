const bcrypt = require("bcryptjs");
const User = require("../models/User");
const RefreshToken = require("../models/RefreshToken");
const crypto = require("crypto");
const {
  generateAccessToken,
  generateRefreshToken,
  hashToken,
} = require("../utils/generateToken");
const { sendPasswordResetEmail } = require("../utils/emailService");
const {
  renderResetPasswordPage,
  renderInvalidTokenPage,
} = require("../utils/resetPageHtml");

const register = async (req, res) => {
  try {
    const name = req.body.name || req.body.username;
    const username = req.body.username || req.body.name;
    const email = req.body.email;
    const password = req.body.password;

    if (!name || !username || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    const existingUser = await User.findOne({
      $or: [{ email: email.toLowerCase() }, { username: username.toLowerCase() }],
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: "Email or username is already taken",
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const user = await User.create({
      name,
      username,
      email,
      password: hashedPassword,
    });

    const accessToken = generateAccessToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    await RefreshToken.create({
      user: user._id,
      tokenHash: hashToken(refreshToken),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    });

    res.status(201).json({
      success: true,
      message: "User registered successfully",
      data: {
        user: {
          id: user._id,
          name: user.name,
          username: user.username,
          email: user.email,
          profileImage: user.profileImage || null,
        },
        accessToken,
        refreshToken,
      },
    });
  } catch (error) {
    console.error("Register error:", error.message);
    res.status(500).json({
      success: false,
      message: "Something went wrong while registering",
    });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    const user = await User.findOne({ email: email.toLowerCase() }).select("+password");

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password",
      });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password",
      });
    }

    const accessToken = generateAccessToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    await RefreshToken.create({
      user: user._id,
      tokenHash: hashToken(refreshToken),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    });

    res.status(200).json({
      success: true,
      message: "Login successful",
      data: {
        user: {
          id: user._id,
          name: user.name,
          username: user.username,
          email: user.email,
          profileImage: user.profileImage || null,
        },
        accessToken,
        refreshToken,
      },
    });
  } catch (error) {
    console.error("Login error:", error.message);
    res.status(500).json({
      success: false,
      message: "Something went wrong while logging in",
    });
  }
};

const jwt = require("jsonwebtoken");

const refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: "Refresh token is required",
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    } catch (err) {
      return res.status(401).json({
        success: false,
        message: "Refresh token is invalid or expired",
      });
    }

    const tokenHash = hashToken(refreshToken);
    const storedToken = await RefreshToken.findOne({ tokenHash });

    if (!storedToken) {
      return res.status(401).json({
        success: false,
        message: "Refresh token is invalid or expired",
      });
    }

    const user = await User.findById(decoded.userId);
    if (!user) {
      await RefreshToken.deleteOne({ _id: storedToken._id });
      return res.status(401).json({
        success: false,
        message: "User account no longer exists",
      });
    }

    // Rotation: delete the old one
    await RefreshToken.deleteOne({ _id: storedToken._id });

    const newAccessToken = generateAccessToken(decoded.userId);
    const newRefreshToken = generateRefreshToken(decoded.userId);

    await RefreshToken.create({
      user: decoded.userId,
      tokenHash: hashToken(newRefreshToken),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    });

    res.status(200).json({
      success: true,
      message: "Token refreshed successfully",
      data: {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      },
    });
  } catch (error) {
    console.error("Refresh error:", error.message);
    res.status(500).json({
      success: false,
      message: "Something went wrong while refreshing token",
    });
  }
};
const logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: "Refresh token is required",
      });
    }

    const tokenHash = hashToken(refreshToken);
    await RefreshToken.deleteOne({ tokenHash });

    res.status(200).json({
      success: true,
      message: "Logged out successfully",
    });
  } catch (error) {
    console.error("Logout error:", error.message);
    res.status(500).json({
      success: false,
      message: "Something went wrong while logging out",
    });
  }
};
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    const cleanEmail = email.toLowerCase().trim();
    const user = await User.findOne({ email: cleanEmail });

    // Always respond with a generic message to prevent account enumeration
    const genericResponse = {
      success: true,
      message: "If that email exists in our system, a password reset link has been sent.",
    };

    if (!user) {
      return res.status(200).json(genericResponse);
    }

    // Rate limiting: prevent spamming resets if one was created in the last 60 seconds
    if (user.resetPasswordExpires && (user.resetPasswordExpires - Date.now()) > 14 * 60 * 1000) {
      return res.status(200).json(genericResponse);
    }

    const resetToken = crypto.randomBytes(32).toString("hex");
    const resetTokenHash = hashToken(resetToken);

    user.resetPasswordToken = resetTokenHash;
    user.resetPasswordExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes
    await user.save();

    // Determine reset URL based on request or environment configuration
    const host = req.get("host");
    const protocol = req.protocol === "https" || req.get("x-forwarded-proto") === "https" ? "https" : "http";
    const baseResetUrl = process.env.CLIENT_RESET_URL || `${protocol}://${host}/api/auth/reset-password`;
    const resetUrl = `${baseResetUrl.replace(/\/$/, "")}/${resetToken}`;

    // Send the password reset email asynchronously
    await sendPasswordResetEmail({
      to: user.email,
      name: user.name,
      resetUrl,
      token: resetToken,
    });

    res.status(200).json({
      ...genericResponse,
      ...(process.env.NODE_ENV !== "production" ? { devResetToken: resetToken } : {}),
    });
  } catch (error) {
    console.error("Forgot password error:", error.message);
    res.status(500).json({
      success: false,
      message: "Something went wrong while processing your request.",
    });
  }
};

const showResetPasswordPage = async (req, res) => {
  try {
    const { token } = req.params;

    if (!token) {
      return res.status(400).send(renderInvalidTokenPage("No reset token provided."));
    }

    const resetTokenHash = hashToken(token);
    const user = await User.findOne({
      resetPasswordToken: resetTokenHash,
      resetPasswordExpires: { $gt: new Date() },
    }).select("+resetPasswordToken +resetPasswordExpires");

    if (!user) {
      return res.status(400).send(renderInvalidTokenPage("This password reset link is invalid or has expired."));
    }

    res.status(200).send(renderResetPasswordPage(token));
  } catch (error) {
    console.error("Show reset page error:", error.message);
    res.status(500).send(renderInvalidTokenPage("An unexpected error occurred. Please try again later."));
  }
};

const resetPassword = async (req, res) => {
  try {
    const resetToken = req.body.resetToken || req.body.token || req.query.token;
    const newPassword = req.body.newPassword || req.body.password;

    if (!resetToken || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Reset token and new password are required",
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 6 characters long",
      });
    }

    const resetTokenHash = hashToken(resetToken);

    const user = await User.findOne({
      resetPasswordToken: resetTokenHash,
      resetPasswordExpires: { $gt: new Date() },
    }).select("+resetPasswordToken +resetPasswordExpires");

    if (!user) {
      return res.status(400).json({
        success: false,
        message: "Reset token is invalid or has expired",
      });
    }

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    user.resetPasswordToken = null;
    user.resetPasswordExpires = null;
    await user.save();

    // Security requirement: Revoke all existing sessions across all devices
    await RefreshToken.deleteMany({ user: user._id });

    res.status(200).json({
      success: true,
      message: "Password reset successful. Please log in with your new password.",
    });
  } catch (error) {
    console.error("Reset password error:", error.message);
    res.status(500).json({
      success: false,
      message: "Something went wrong while resetting your password.",
    });
  }
};

const googleAuth = async (req, res) => {
  try {
    const { email, name, profileImage, googleId } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required for Google Sign-In",
      });
    }

    const cleanEmail = email.toLowerCase().trim();
    const cleanName = (name || cleanEmail.split("@")[0] || "User").trim();
    const cleanGoogleId = googleId ? String(googleId).trim() : null;
    const cleanProfileImage = profileImage ? String(profileImage).trim() : null;

    let user = await User.findOne({
      $or: [
        ...(cleanGoogleId ? [{ googleId: cleanGoogleId }] : []),
        { email: cleanEmail },
      ],
    });

    if (user) {
      let needsSave = false;
      if (cleanGoogleId && !user.googleId) {
        user.googleId = cleanGoogleId;
        needsSave = true;
      }
      if (cleanProfileImage && user.profileImage !== cleanProfileImage) {
        user.profileImage = cleanProfileImage;
        needsSave = true;
      }
      if (!user.name && cleanName) {
        user.name = cleanName;
        needsSave = true;
      }
      if (needsSave) {
        await user.save();
      }
    } else {
      // Create unique username from email/name
      let baseUsername = cleanEmail.split("@")[0].replace(/[^a-zA-Z0-9_]/g, "").toLowerCase();
      if (!baseUsername) baseUsername = "user";
      let uniqueUsername = baseUsername;
      let counter = 1;
      while (await User.findOne({ username: uniqueUsername })) {
        uniqueUsername = `${baseUsername}${counter}`;
        counter++;
      }

      // Generate random salt & hash for password if required
      const randomPassword = crypto.randomBytes(16).toString("hex");
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(randomPassword, salt);

      user = await User.create({
        name: cleanName,
        username: uniqueUsername,
        email: cleanEmail,
        password: hashedPassword,
        googleId: cleanGoogleId,
        profileImage: cleanProfileImage,
        isEmailVerified: true,
      });
    }

    const accessToken = generateAccessToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    await RefreshToken.create({
      user: user._id,
      tokenHash: hashToken(refreshToken),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    });

    res.status(200).json({
      success: true,
      message: "Google authentication successful",
      data: {
        user: {
          id: user._id,
          name: user.name,
          username: user.username,
          email: user.email,
          profileImage: user.profileImage || null,
        },
        accessToken,
        refreshToken,
      },
    });
  } catch (error) {
    console.error("Google auth error:", error);
    res.status(500).json({
      success: false,
      message: "Something went wrong during Google sign in",
    });
  }
};

module.exports = {
  register,
  login,
  refresh,
  logout,
  forgotPassword,
  showResetPasswordPage,
  resetPassword,
  googleAuth,
};


