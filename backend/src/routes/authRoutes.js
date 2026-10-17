const express = require("express");
const { protect } = require("../middleware/authMiddleware"); // ADD THIS
const {
  register,
  login,
  refresh,
  logout,
  forgotPassword,
  showResetPasswordPage,
  resetPassword,
  googleAuth,
} = require("../controllers/authController");

const router = express.Router();

router.post("/register", register);
router.post("/login", login);
router.post("/google", googleAuth);
router.post("/refresh", refresh);
router.post("/logout", logout);
router.post("/forgot-password", forgotPassword);
router.get("/reset-password/:token", showResetPasswordPage);
router.post("/reset-password", resetPassword);

// Temporary test route — proves middleware works
router.get("/me", protect, (req, res) => {
  res.status(200).json({
    success: true,
    message: "You are authenticated",
    userId: req.user.id,
  });
});

module.exports = router;