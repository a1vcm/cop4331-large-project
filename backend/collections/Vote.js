const { Schema, model } = require("mongoose");

const voteSchema = new Schema(
  {
    reviewId: { type: Schema.Types.ObjectId, ref: "Review", required: true },
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    value: { type: Number, enum: [1, -1], required: true }, //1 = helpful, -1 = not helpful
  },
  { timestamps: true }
);

// The constraint: at most one vote per user per review.
// A second insert with the same pair throws a duplicate-key error (code 11000).
voteSchema.index({ reviewId: 1, userId: 1 }, { unique: true });

module.exports = model("Vote", voteSchema);