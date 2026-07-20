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
    // Set while an email change is awaiting verification; the code fields
    // above are reused for the change-email code (they're unused once a
    // user is verified).
    pendingEmail: { type: String, lowercase: true, trim: true },
  },
  { timestamps: true }
);
 
module.exports = model("User", userSchema);
