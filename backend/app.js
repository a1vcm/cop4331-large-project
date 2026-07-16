require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');
const { connectDB } = require('./db');

require("./collections/Course");
require("./collections/Instructor");
require("./collections/Review");
require("./collections/User");
require("./collections/Vote");

const dbReady = connectDB();

const app = express();
app.use(express.json());
app.use(cors());

const url = process.env.MONGODB_URI || 'mongodb://localhost:27017/poost';
const client = new MongoClient(url);

// Test endpoint
app.get('/api/health', async (req, res) => {
  try {
    await client.connect();
    await client.db().command({ ping: 1 });
    res.status(200).json({ status: 'ok', message: 'Connected to MongoDB' });
  } catch (e) {
    res.status(500).json({ status: 'error', message: e.toString() });
  }
});

app.use('/api/auth', require('./routes/auth-routes'));
app.use('/api/courses', require('./routes/course-routes'));
app.use('/api/reviews', require('./routes/review-routes'));

module.exports = { app, client, dbReady };
