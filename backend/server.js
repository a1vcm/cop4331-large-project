require('dotenv').config(); // MUST BE LINE 1
console.log("DEBUG MONGO_URI FROM SERVER:", process.env.MONGO_URI); // <-- ADD THIS
const express = require('express');


const { app } = require('./app');
const connectDB = require('./db'); // Import the database connection logic

connectDB(); // force connection

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
