const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../collections/User');
const { sendEmail } = require('../utils/mailer');
const { generateCode, minutesFromNow } = require('../utils/codes');

const VERIFICATION_CODE_TTL_MIN = 15;
const RESET_CODE_TTL_MIN = 30;

function generateToken(userId) {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '30d' });
}

// Edit these two functions to customize the wording/branding of the emails.
function verificationEmail(code) {
  return {
    subject: 'Verify your KnightRate email',
    text: `Your KnightRate verification code is ${code}. It expires in ${VERIFICATION_CODE_TTL_MIN} minutes.`,
    html: `<p>Your KnightRate verification code is <strong>${code}</strong>.</p><p>It expires in ${VERIFICATION_CODE_TTL_MIN} minutes.</p>`,
  };
}

function passwordResetEmail(code) {
  return {
    subject: 'Reset your KnightRate password',
    text: `Your KnightRate password reset code is ${code}. It expires in ${RESET_CODE_TTL_MIN} minutes. If you didn't request this, you can ignore this email.`,
    html: `<p>Your KnightRate password reset code is <strong>${code}</strong>.</p><p>It expires in ${RESET_CODE_TTL_MIN} minutes. If you didn't request this, you can ignore this email.</p>`,
  };
}

// POST /api/auth/register
async function registerUser(req, res) {
  try {
    const { username, email, password } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ message: 'username, email, and password are required' });
    }

    const normalizedEmail = email.toLowerCase().trim();

    // 1. Search for a pre-existing account
    const existing = await User.findOne({ email: normalizedEmail });
    
    // 2. FIXED: Only reject if the existing account is actually VERIFIED
    if (existing && existing.isVerified) {
      return res.status(409).json({ message: 'An account with that email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const verificationCode = generateCode();
    const expiryTime = minutesFromNow(VERIFICATION_CODE_TTL_MIN);

    let user;
    if (existing && !existing.isVerified) {
      // If the account exists but was never verified, reuse the document space
      existing.username = username;
      existing.passwordHash = passwordHash;
      existing.verificationCode = verificationCode;
      existing.verificationCodeExpires = expiryTime;
      user = await existing.save();
    } else {
      // Brand new registration path
      user = await User.create({
        username,
        email: normalizedEmail, // FIXED: Save normalized lowercase string
        passwordHash,
        isVerified: false,
        verificationCode,
        verificationCodeExpires: expiryTime,
      });
    }

    await sendEmail({ to: user.email, ...verificationEmail(verificationCode) });

    res.status(201).json({
      message: 'Registered. Check your email for a verification code.',
      email: user.email,
    });
  } catch (err) {
    res.status(500).json({ message: 'Registration failed', error: err.message });
  }
}

// POST /api/auth/verify-email
async function verifyEmail(req, res) {
  try {
    const { email, code } = req.body;
    if (!email || !code) {
      return res.status(400).json({ message: 'email and code are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'No account with that email' });
    }

    if (user.isVerified) {
      return res.json({
        message: 'Email already verified',
        id: user._id,
        username: user.username,
        email: user.email,
        token: generateToken(user._id),
      });
    }

    const isExpired = !user.verificationCodeExpires || user.verificationCodeExpires < new Date();
    if (user.verificationCode !== code || isExpired) {
      return res.status(400).json({ message: 'Invalid or expired verification code' });
    }

    user.isVerified = true;
    user.verificationCode = undefined;
    user.verificationCodeExpires = undefined;
    await user.save();

    res.json({
      message: 'Email verified',
      id: user._id,
      username: user.username,
      email: user.email,
      token: generateToken(user._id),
    });
  } catch (err) {
    res.status(500).json({ message: 'Verification failed', error: err.message });
  }
}

// POST /api/auth/resend-verification
async function resendVerification(req, res) {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: 'email is required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'No account with that email' });
    }
    if (user.isVerified) {
      return res.status(400).json({ message: 'Email is already verified' });
    }

    const verificationCode = generateCode();
    user.verificationCode = verificationCode;
    user.verificationCodeExpires = minutesFromNow(VERIFICATION_CODE_TTL_MIN);
    await user.save();

    await sendEmail({ to: user.email, ...verificationEmail(verificationCode) });

    res.json({ message: 'Verification code resent' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to resend code', error: err.message });
  }
}

// POST /api/auth/login
async function loginUser(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'email and password are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    const valid = user && (await bcrypt.compare(password, user.passwordHash));
    if (!valid) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    if (!user.isVerified) {
      return res.status(403).json({ message: 'Please verify your email before logging in', unverified: true });
    }

    res.json({
      id: user._id,
      username: user.username,
      email: user.email,
      token: generateToken(user._id),
    });
  } catch (err) {
    res.status(500).json({ message: 'Login failed', error: err.message });
  }
}

// POST /api/auth/forgot-password
async function forgotPassword(req, res) {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: 'email is required' });
    }

    const genericResponse = { message: 'If that email is registered, a reset code has been sent.' };
    const user = await User.findOne({ email: email.toLowerCase() });
    
    // FIXED: Block unverified users from abusing the password reset system
    if (!user || !user.isVerified) {
      return res.json(genericResponse);
    }

    const passwordResetCode = generateCode();
    user.passwordResetCode = passwordResetCode;
    user.passwordResetExpires = minutesFromNow(RESET_CODE_TTL_MIN);
    await user.save();

    await sendEmail({ to: user.email, ...passwordResetEmail(passwordResetCode) });

    res.json(genericResponse);
  } catch (err) {
    res.status(500).json({ message: 'Failed to process request', error: err.message });
  }
}

// POST /api/auth/reset-password
async function resetPassword(req, res) {
  try {
    const { email, code, newPassword } = req.body;
    if (!email || !code || !newPassword) {
      return res.status(400).json({ message: 'email, code, and newPassword are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    const isExpired = !user || !user.passwordResetExpires || user.passwordResetExpires < new Date();
    if (!user || user.passwordResetCode !== code || isExpired) {
      return res.status(400).json({ message: 'Invalid or expired reset code' });
    }

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    user.passwordResetCode = undefined;
    user.passwordResetExpires = undefined;
    await user.save();

    res.json({ message: 'Password reset successful. You can now log in.' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to reset password', error: err.message });
  }
}

module.exports = {
  registerUser,
  verifyEmail,
  resendVerification,
  loginUser,
  forgotPassword,
  resetPassword,
};