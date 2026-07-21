const { Schema, model } = require("mongoose");
 
const courseSchema = new Schema
(
  {
    course_code: { type: String, required: true, unique: true, trim: true },
    title: { type: String, required: true, trim: true },
    department: { type: String, trim: true },
    credits: Number,
    avgRating: { type: Number, default: 0 },
    avgDifficulty: { type: Number, default: 0 },
    numRatings: { type: Number, default: 0 },
    lastReviewedAt: { type: Date, default: null },
  },
  { timestamps: true }
);
 
//Search indexes for course_code and title, and a separate index for department
courseSchema.index({ course_code: "text", title: "text" });
courseSchema.index({ department: 1 });
 
module.exports = model("Course", courseSchema);