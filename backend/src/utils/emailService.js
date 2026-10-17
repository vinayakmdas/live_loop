const nodemailer = require("nodemailer");

/**
 * Creates and configures the Nodemailer transporter.
 * Supports standard SMTP (host, port, user, pass) or service (e.g. 'gmail').
 */
const createTransporter = () => {
  const host = process.env.SMTP_HOST;
  const port = parseInt(process.env.SMTP_PORT || "587", 10);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const service = process.env.SMTP_SERVICE;

  if (service) {
    return nodemailer.createTransport({
      service,
      auth: { user, pass },
    });
  }

  if (host && user && pass) {
    return nodemailer.createTransport({
      host,
      port,
      secure: port === 465, // true for 465, false for 587/other
      auth: { user, pass },
      tls: {
        rejectUnauthorized: process.env.NODE_ENV === "production",
      },
    });
  }

  return null;
};

/**
 * Sends a password reset email to the user.
 * If SMTP credentials are not configured, logs the reset link to the console for development.
 *
 * @param {Object} options
 * @param {string} options.to - Recipient email address
 * @param {string} options.name - Recipient name
 * @param {string} options.resetUrl - Full URL to the password reset page
 * @param {string} options.token - The raw reset token
 * @returns {Promise<{ delivered: boolean, previewOnly: boolean }>}
 */
const sendPasswordResetEmail = async ({ to, name, resetUrl, token }) => {
  const transporter = createTransporter();
  const from = process.env.EMAIL_FROM || process.env.SMTP_USER || "Live Loop Support <no-reply@liveloop.app>";

  const recipientName = name || to.split("@")[0] || "Live Loop User";

  const textContent = `Hello ${recipientName},\n\nWe received a request to reset your password for your Live Loop account.\n\nClick the link below to choose a new password (valid for 15 minutes):\n${resetUrl}\n\nYour reset token is: ${token}\n\nIf you did not request this, you can safely ignore this email. Your password will remain unchanged.\n\n— The Live Loop Team`;

  const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Your Live Loop Password</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0B0F19; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #FFFFFF;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0B0F19; padding: 40px 15px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width: 520px; background-color: #171A24; border-radius: 16px; border: 1px solid #2A3042; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
          <!-- Header -->
          <tr>
            <td style="padding: 32px 32px 16px 32px; text-align: center;">
              <div style="display: inline-block; padding: 10px 20px; border-radius: 9999px; background: linear-gradient(135deg, #5748EF 0%, #4B3BD9 100%); color: #FFFFFF; font-size: 18px; font-weight: 700; letter-spacing: 0.5px;">
                Live Loop
              </div>
              <h2 style="margin: 24px 0 8px 0; color: #FFFFFF; font-size: 22px; font-weight: 700;">Password Reset Request</h2>
              <p style="margin: 0; color: #9E9E9E; font-size: 14px;">Hello, <strong style="color: #FFFFFF;">${recipientName}</strong></p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding: 16px 32px 32px 32px;">
              <p style="margin: 0 0 20px 0; color: #CCCCCC; font-size: 15px; line-height: 1.6;">
                We received a request to reset the password associated with your account (<strong>${to}</strong>).
              </p>
              
              <div style="text-align: center; margin: 30px 0;">
                <a href="${resetUrl}" target="_blank" style="display: inline-block; background-color: #4F46E5; background-image: linear-gradient(135deg, #5748EF 0%, #4B3BD9 100%); color: #FFFFFF; text-decoration: none; padding: 14px 32px; border-radius: 10px; font-size: 15px; font-weight: 600; box-shadow: 0 4px 14px rgba(79, 70, 229, 0.4);">
                  Reset Password
                </a>
              </div>

              <div style="background-color: #1E2333; border-radius: 8px; padding: 14px 18px; margin: 24px 0; border-left: 3px solid #4F46E5;">
                <p style="margin: 0 0 6px 0; color: #9E9E9E; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">
                  Or use this token directly in the app:
                </p>
                <code style="display: block; word-break: break-all; color: #A5B4FC; font-size: 13px; font-family: monospace;">${token}</code>
              </div>

              <p style="margin: 0 0 12px 0; color: #9E9E9E; font-size: 13px; line-height: 1.5;">
                Or paste this link into your browser:<br>
                <a href="${resetUrl}" style="color: #6366F1; word-break: break-all; text-decoration: underline;">${resetUrl}</a>
              </p>

              <hr style="border: none; border-top: 1px solid #2A3042; margin: 24px 0;">

              <p style="margin: 0; color: #757575; font-size: 12px; line-height: 1.5;">
                <strong>Security Notice:</strong> This link is valid for <strong>15 minutes</strong> and can only be used once. If you did not request a password reset, no action is needed — your account remains completely secure.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 16px 32px 24px 32px; text-align: center; background-color: #12151E; border-top: 1px solid #2A3042;">
              <p style="margin: 0; color: #616161; font-size: 12px;">
                &copy; ${new Date().getFullYear()} Live Loop. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `;

  if (!transporter) {
    console.log("\n" + "=".repeat(70));
    console.log("  [DEV EMAIL SERVICE] No SMTP credentials configured in .env");
    console.log(`  To:           ${to}`);
    console.log(`  Subject:      Reset Your Live Loop Password`);
    console.log(`  Reset Link:   ${resetUrl}`);
    console.log(`  Reset Token:  ${token}`);
    console.log(`  Expires in:   15 minutes`);
    console.log("  (To send real emails, set SMTP_HOST, SMTP_USER, SMTP_PASS in backend/.env)");
    console.log("=".repeat(70) + "\n");

    return { delivered: false, previewOnly: true, resetUrl, token };
  }

  try {
    const info = await transporter.sendMail({
      from,
      to,
      subject: "Reset Your Live Loop Password",
      text: textContent,
      html: htmlContent,
    });

    console.log(`[EmailService] Password reset email sent to ${to} (MessageId: ${info.messageId})`);
    return { delivered: true, previewOnly: false, messageId: info.messageId };
  } catch (error) {
    console.error(`[EmailService] Failed to send email to ${to}:`, error.message);
    // Don't leak SMTP internal errors to callers
    return { delivered: false, previewOnly: false, error: error.message };
  }
};

module.exports = {
  sendPasswordResetEmail,
};
