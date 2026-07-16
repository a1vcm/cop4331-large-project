// middleware/authMiddleware.js
const jwt = require('jsonwebtoken');
const User = require('../collections/User');

const protect = async (req, res, next) => {
  let token;

  // Check for the "Authorization: Bearer <token>" header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Extract token from header
      token = req.headers.authorization.split(' ')[1];

      // Verify the token using your secret
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Fetch the user from the database and attach to the request object (excluding password hash)
      req.user = await User.findById(decoded.id).select('-passwordHash');

      if (!req.user) {
        return res.status(401).json({ message: 'Not authorized, user not found' });
      }

      return next(); // Proceed to the controller!
    } catch (error) {
      console.error('[auth-middleware] Token verification failed:', error.message);
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    return res.status(401).json({ message: 'Not authorized, no token provided' });
  }
};

module.exports = protect;