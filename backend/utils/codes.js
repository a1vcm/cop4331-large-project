// 6-digit numeric codes used for both email verification and password reset.
function generateCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function minutesFromNow(minutes) {
  return new Date(Date.now() + minutes * 60 * 1000);
}

module.exports = { generateCode, minutesFromNow };
