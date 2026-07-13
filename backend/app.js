// require('dotenv').config(); // same line in server.js

require('dotenv').config(); // 1. ALWAYS FIRST
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose'); // Import mongoose directly for health checking
const connectDB = require('./db'); // Clean import

// Load Schemas
require("./collections/Course");
require("./collections/Instructor");
require("./collections/Review");
require("./collections/User");
require("./collections/Vote");

const app = express();
app.use(express.json());
app.use(cors());

// Establish Mongoose Connection
connectDB(); 

// Cleaned Health Endpoint using Mongoose status states
app.get('/api/health', (req, res) => {
    // mongoose.connection.readyState returns 1 if fully connected
    if (mongoose.connection.readyState === 1) {
        return res.status(200).json({ status: 'ok', message: 'Connected to MongoDB via Mongoose' });
    } else {
        return res.status(500).json({ status: 'error', message: 'Database disconnected' });
    }
});

// Routes
app.use('/api/auth', require('./routes/auth-routes'));
app.use('/api/courses', require('./routes/course-routes'));

module.exports = { app };
