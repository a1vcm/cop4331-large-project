const { Schema, model } = require("mongoose");

const bookmarkSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    reviewId: { type: Schema.Types.ObjectId, ref: "Review", required: true },
  },
  { timestamps: true }
);

// At most one bookmark per user per review. Indexed userId-first since the
// dominant query is "all of this user's bookmarks" (GET /mine).
bookmarkSchema.index({ userId: 1, reviewId: 1 }, { unique: true });

module.exports = model("Bookmark", bookmarkSchema);
