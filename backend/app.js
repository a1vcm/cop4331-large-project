// require('dotenv').config(); // same line in server.js

const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');

// app.js snippet
const app = express();


require("./collections/Course");
require("./collections/Instructor");
require("./collections/Review");
require("./collections/User");
require("./collections/Vote");

app.use(express.json());
app.use(cors());

// Middleware to parse JSON bodies
app.use(express.json());

// Mount your API routes
app.use('/api/courses', require('./routes/course-routes'));
app.use('/api/auth', require('./routes/auth-routes'));

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

module.exports = { app, client };
