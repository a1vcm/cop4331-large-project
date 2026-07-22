const { Schema, model } = require("mongoose");
const { REVIEW_TAGS } = require("../utils/reviewTags");

const GRADE_OPTIONS = [
  'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'W', 'P', '',
];

const reviewSchema = new Schema(
  {
    courseId: { type: Schema.Types.ObjectId, ref: "Course", required: true },
    userId: { type: Schema.Types.ObjectId, ref: "User" },
    instructor: { type: String, trim: true },
    term: { type: String, trim: true },
    quality: {
      type: Number,
      min: 1,
      max: 5,
      required: true,
      // Half-star increments only (1, 1.5, 2, ... 5).
      validate: {
        validator: (v) => Number.isInteger(v * 2),
        message: 'quality must be in half-star increments',
      },
    },
    difficulty: { type: Number, min: 1, max: 5, required: true },
    workload: { type: Number, min: 1, max: 5 },
    gradingFairness: { type: Number, min: 1, max: 5 },
    professorRating: { type: Number, min: 1, max: 5 },
    attendance: { type: Number, min: 1, max: 5 },
    grade: { type: String, enum: GRADE_OPTIONS, default: '' },
    comment: { type: String, maxlength: 2000, trim: true },
    tags: { type: [String], enum: REVIEW_TAGS, default: [] },
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