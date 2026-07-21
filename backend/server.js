// // server.js
// require('dotenv').config();
// const { app } = require('./app'); // Only import the configured app instance
// const PORT = process.env.PORT || 5001;

// // Start listening for network requests
// const server = app.listen(PORT, () => {
//     console.log(`Server running in production mode on port ${PORT}`);
// });

// // Handle unhandled promise rejections (e.g., if database falls over mid-runtime)
// process.on('unhandledRejection', (err, promise) => {
//     console.error(`Critical Error: ${err.message}`);
//     // Close server & exit process
//     server.close(() => process.exit(1));
// });

// UNIT TESTING server.js
require('dotenv').config();
const app = require('./app');
const { connectDB } = require('./db');

const PORT = process.env.PORT || 5001;

// Connect to DB first, then start server
connectDB()
  .then(() => {
    console.log('[db] MongoDB connected successfully');
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Database connection error:', err);
    process.exit(1);
  });
