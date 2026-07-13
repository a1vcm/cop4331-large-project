const mongoose = require("mongoose");

async function connectDB()
{
  try {
    //await mongoose.connect(process.env.MONGODB_URI); // old code dont use, fix is below
    const uri = process.env.MONGODB_URI; 
        
    const conn = await mongoose.connect(uri);
    console.log("[db] MongoDB connected");
  } catch (err) {
    console.error("[db] Connection error:", err.message);
    process.exit(1); //stop the app if DB connection fails
  }
}

// module.exports = { connectDB }; // old code
module.exports = { connectDB }; // new cleaner export
