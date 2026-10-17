/**
 * Renders the HTML for the Password Reset Web Page.
 * Styled with Live Loop's dark mode design system (#0B0F19, #171A24, #4F46E5).
 */
const renderResetPasswordPage = (token) => {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Password • Live Loop</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: #0B0F19;
      color: #FFFFFF;
      font-family: 'Outfit', -apple-system, BlinkMacSystemFont, sans-serif;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
      background-image: radial-gradient(circle at 50% 0%, rgba(79, 70, 229, 0.15) 0%, transparent 60%);
    }
    .card {
      width: 100%;
      max-width: 440px;
      background: #171A24;
      border: 1px solid #262B3B;
      border-radius: 20px;
      padding: 36px 32px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.45);
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
      margin-bottom: 24px;
    }
    .logo-badge {
      width: 40px;
      height: 40px;
      border-radius: 12px;
      background: linear-gradient(135deg, #5748EF 0%, #4B3BD9 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      font-size: 20px;
    }
    .brand-name {
      font-size: 20px;
      font-weight: 700;
      color: #FFFFFF;
      letter-spacing: -0.3px;
    }
    h1 {
      font-size: 24px;
      font-weight: 700;
      margin-bottom: 8px;
      color: #FFFFFF;
    }
    .subtitle {
      font-size: 14px;
      color: #94A3B8;
      margin-bottom: 28px;
      line-height: 1.5;
    }
    .form-group {
      margin-bottom: 20px;
    }
    label {
      display: block;
      font-size: 13px;
      font-weight: 600;
      color: #CBD5E1;
      margin-bottom: 8px;
      letter-spacing: 0.2px;
    }
    .input-wrapper {
      position: relative;
    }
    input[type="password"], input[type="text"] {
      width: 100%;
      height: 50px;
      background: #0B0F19;
      border: 1px solid #2E364A;
      border-radius: 12px;
      padding: 0 46px 0 16px;
      font-size: 15px;
      color: #FFFFFF;
      outline: none;
      font-family: inherit;
      transition: border-color 0.2s, box-shadow 0.2s;
    }
    input:focus {
      border-color: #4F46E5;
      box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.2);
    }
    .toggle-pw {
      position: absolute;
      right: 14px;
      top: 50%;
      transform: translateY(-50%);
      background: none;
      border: none;
      cursor: pointer;
      color: #64748B;
      padding: 4px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .toggle-pw:hover { color: #CBD5E1; }
    .rules {
      margin-top: 10px;
      font-size: 12px;
      color: #64748B;
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .rule-item {
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .rule-item.valid { color: #10B981; }
    .rule-item.invalid { color: #EF4444; }
    .btn {
      width: 100%;
      height: 50px;
      background: linear-gradient(135deg, #5748EF 0%, #4B3BD9 100%);
      border: none;
      border-radius: 12px;
      color: #FFFFFF;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      font-family: inherit;
      transition: opacity 0.2s, transform 0.1s;
      margin-top: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 14px rgba(79, 70, 229, 0.35);
    }
    .btn:hover:not(:disabled) {
      opacity: 0.95;
      transform: translateY(-1px);
    }
    .btn:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
    .alert {
      padding: 12px 16px;
      border-radius: 10px;
      font-size: 14px;
      margin-bottom: 20px;
      display: none;
    }
    .alert-error {
      background: rgba(239, 68, 68, 0.15);
      border: 1px solid rgba(239, 68, 68, 0.3);
      color: #FCA5A5;
    }
    .success-view {
      display: none;
      text-align: center;
      padding: 10px 0;
    }
    .success-icon {
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: rgba(16, 185, 129, 0.15);
      border: 2px solid #10B981;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px auto;
      color: #10B981;
    }
  </style>
</head>
<body>
  <div class="card" id="mainCard">
    <div class="brand">
      <div class="logo-badge">L</div>
      <div class="brand-name">Live Loop</div>
    </div>

    <!-- Form Section -->
    <div id="formSection">
      <h1>Reset Password</h1>
      <p class="subtitle">Enter your new password below to regain access to your account.</p>

      <div class="alert alert-error" id="errorBox"></div>

      <form id="resetForm" onsubmit="handleReset(event)">
        <input type="hidden" id="resetToken" value="${token}">

        <div class="form-group">
          <label for="newPassword">New Password</label>
          <div class="input-wrapper">
            <input type="password" id="newPassword" placeholder="••••••••" required autocomplete="new-password">
            <button type="button" class="toggle-pw" onclick="toggleVisibility('newPassword', this)" aria-label="Toggle password visibility">
              <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
            </button>
          </div>
        </div>

        <div class="form-group">
          <label for="confirmPassword">Confirm New Password</label>
          <div class="input-wrapper">
            <input type="password" id="confirmPassword" placeholder="••••••••" required autocomplete="new-password">
            <button type="button" class="toggle-pw" onclick="toggleVisibility('confirmPassword', this)" aria-label="Toggle password visibility">
              <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
            </button>
          </div>
          <div class="rules">
            <div class="rule-item" id="lengthRule"><span>•</span> Minimum 6 characters</div>
            <div class="rule-item" id="matchRule"><span>•</span> Passwords must match</div>
          </div>
        </div>

        <button type="submit" class="btn" id="submitBtn">
          <span>Reset Password</span>
        </button>
      </form>
    </div>

    <!-- Success Section -->
    <div class="success-view" id="successSection">
      <div class="success-icon">
        <svg width="32" height="32" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/></svg>
      </div>
      <h1>Password Updated</h1>
      <p class="subtitle" style="margin-bottom: 24px;">Your password has been changed successfully. You can now open the Live Loop app and sign in with your new credentials.</p>
      
      <a href="liveloop://login" style="text-decoration: none;">
        <button type="button" class="btn" style="margin-bottom: 12px;">Open Live Loop App</button>
      </a>
      <p style="font-size: 13px; color: #64748B; margin-top: 16px;">All previous sessions on other devices have been logged out for security.</p>
    </div>
  </div>

  <script>
    const newPw = document.getElementById('newPassword');
    const confirmPw = document.getElementById('confirmPassword');
    const lengthRule = document.getElementById('lengthRule');
    const matchRule = document.getElementById('matchRule');
    const submitBtn = document.getElementById('submitBtn');
    const errorBox = document.getElementById('errorBox');

    function checkRules() {
      const p1 = newPw.value;
      const p2 = confirmPw.value;

      const isLenValid = p1.length >= 6;
      lengthRule.className = 'rule-item ' + (p1 ? (isLenValid ? 'valid' : 'invalid') : '');

      const isMatchValid = isLenValid && p1 === p2 && p2.length > 0;
      matchRule.className = 'rule-item ' + (p2 ? (isMatchValid ? 'valid' : 'invalid') : '');
    }

    newPw.addEventListener('input', checkRules);
    confirmPw.addEventListener('input', checkRules);

    function toggleVisibility(id, btn) {
      const input = document.getElementById(id);
      if (input.type === 'password') {
        input.type = 'text';
        btn.style.color = '#4F46E5';
      } else {
        input.type = 'password';
        btn.style.color = '#64748B';
      }
    }

    async function handleReset(e) {
      e.preventDefault();
      errorBox.style.display = 'none';

      const token = document.getElementById('resetToken').value;
      const newPassword = newPw.value;
      const confirmPassword = confirmPw.value;

      if (newPassword.length < 6) {
        showError('Password must be at least 6 characters long');
        return;
      }
      if (newPassword !== confirmPassword) {
        showError('Passwords do not match');
        return;
      }

      submitBtn.disabled = true;
      submitBtn.innerHTML = '<span>Updating...</span>';

      try {
        const res = await fetch('/api/auth/reset-password', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ resetToken: token, newPassword })
        });

        const data = await res.json();

        if (res.ok && data.success) {
          document.getElementById('formSection').style.display = 'none';
          document.getElementById('successSection').style.display = 'block';
        } else {
          showError(data.message || 'Failed to reset password. The link may have expired.');
          submitBtn.disabled = false;
          submitBtn.innerHTML = '<span>Reset Password</span>';
        }
      } catch (err) {
        showError('Network error. Please check your internet connection.');
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<span>Reset Password</span>';
      }
    }

    function showError(msg) {
      errorBox.textContent = msg;
      errorBox.style.display = 'block';
    }
  </script>
</body>
</html>`;
};

/**
 * Renders an error page when a reset link is expired or invalid.
 */
const renderInvalidTokenPage = (message = "This password reset link is invalid or has expired.") => {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invalid Link • Live Loop</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: #0B0F19;
      color: #FFFFFF;
      font-family: 'Outfit', sans-serif;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
      text-align: center;
    }
    .card {
      max-width: 420px;
      background: #171A24;
      border: 1px solid #262B3B;
      border-radius: 20px;
      padding: 40px 32px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.5);
    }
    .icon {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background: rgba(239, 68, 68, 0.15);
      border: 2px solid #EF4444;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px auto;
      color: #EF4444;
    }
    h1 { font-size: 22px; margin-bottom: 12px; }
    p { font-size: 14px; color: #94A3B8; line-height: 1.6; margin-bottom: 24px; }
    .btn {
      display: inline-block;
      width: 100%;
      height: 48px;
      line-height: 48px;
      background: #4F46E5;
      color: #FFFFFF;
      border-radius: 12px;
      text-decoration: none;
      font-weight: 600;
      font-size: 15px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">
      <svg width="28" height="28" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
    </div>
    <h1>Link Expired or Invalid</h1>
    <p>${message} Password reset links are single-use and expire after 15 minutes for your security.</p>
    <a href="liveloop://forgot-password" class="btn">Open App to Request New Link</a>
  </div>
</body>
</html>`;
};

module.exports = {
  renderResetPasswordPage,
  renderInvalidTokenPage,
};
