const { Schema, model } = require("mongoose");

const resourceSchema = new Schema(
  {
    courseId: { type: Schema.Types.ObjectId, ref: "Course", required: true },
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    title: { type: String, required: true, trim: true, maxlength: 120 },
    url: {
      type: String,
      required: true,
      trim: true,
      validate: {
        validator: (v) => /^https?:\/\//i.test(v),
        message: 'url must start with http:// or https://',
      },
    },
  },
  { timestamps: true }
);

resourceSchema.index({ courseId: 1, createdAt: -1 });

module.exports = model("Resource", resourceSchema);
