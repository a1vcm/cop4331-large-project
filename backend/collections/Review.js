const { Schema, model } = require("mongoose");

const reviewSchema = new Schema(
  {
    courseId: { type: Schema.Types.ObjectId, ref: "Course", required: true },
    userId: { type: Schema.Types.ObjectId, ref: "User" },
    instructor: { type: String, trim: true },
    term: { type: String, trim: true },
    quality: { type: Number, min: 1, max: 5, required: true },
    difficulty: { type: Number, min: 1, max: 5, required: true },
    grade: String,
    comment: { type: String, maxlength: 1000, trim: true },
    voteScore: {
      helpful: { type: Number, default: 0 },
      notHelpful: { type: Number, default: 0 },
    }, // 1= helpful, -1 = not helpful
  },
  { timestamps: true }
);

//Search indexes for course page and user's reviews
reviewSchema.index({ courseId: 1, createdAt: -1 });
reviewSchema.index({ userId: 1 });

module.exports = model("Review", reviewSchema);