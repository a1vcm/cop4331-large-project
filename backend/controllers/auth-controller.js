const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../collections/User');

function generateToken(userId) {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '30d' });
}

// POST /api/auth/register
async function registerUser(req, res) {
  try {
    const { username, email, password } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ message: 'username, email, and password are required' });
    }

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(409).json({ message: 'An account with that email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ username, email, passwordHash });

    res.status(201).json({
      id: user._id,
      username: user.username,
      email: user.email,
      token: generateToken(user._id),
    });
  } catch (err) {
    res.status(500).json({ message: 'Registration failed', error: err.message });
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

module.exports = { registerUser, loginUser };
