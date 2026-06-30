require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');

const app = express();
app.use(express.json());
app.use(cors());

const url = process.env.MONGODB_URI;
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

const PORT = 5001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});