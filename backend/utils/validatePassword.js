const MIN_LENGTH = 8;

// Shared password rule for register / reset-password / change-password.
function validatePassword(password) {
  if (typeof password !== 'string' || password.length < MIN_LENGTH) {
    return { valid: false, message: `Password must be at least ${MIN_LENGTH} characters` };
  }
  return { valid: true, message: null };
}

module.exports = { validatePassword, MIN_LENGTH };
