// routes/users-routes.js
const express = require('express');
const router = express.Router();
const {
  changeUsername,
  requestEmailChange,
  verifyEmailChange,
  changePassword,
  deleteAccount,
} = require('../controllers/users-controller');

const protect = require('../middleware/authMiddleware');

// Every account-management route requires a valid JWT.
router.put('/username', protect, changeUsername);
router.post('/email/request', protect, requestEmailChange);
router.post('/email/verify', protect, verifyEmailChange);
router.put('/password', protect, changePassword);
router.delete('/me', protect, deleteAccount);

module.exports = router;
