// utils/codes.js

// Generates a 6-digit numeric code
function generateCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

// FIXED: Generates an absolute UTC timestamp representation
function minutesFromNow(minutes) {
  const date = new Date(Date.now() + minutes * 60 * 1000);
  return date; // Saved cleanly to MongoDB as an ISODate
}

module.exports = { generateCode, minutesFromNow };;