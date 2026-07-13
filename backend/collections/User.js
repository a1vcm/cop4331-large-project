const { Schema, model } = require("mongoose");
 
const userSchema = new Schema(
  {
    username: { type: String, required: true},
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: { type: String, required: true },
    isVerified: { type: Boolean, default: false },
    verificationCode: String,
    verificationCodeExpires: Date,
    passwordResetCode: String,
    passwordResetExpires: Date,
  },
  { timestamps: true }
);
 
module.exports = model("User", userSchema);
