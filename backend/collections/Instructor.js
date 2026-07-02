const { Schema, model } = require("mongoose");

const instructorSchema = new Schema(
  {
    firstname: { type: String, required: true, trim: true },
    lastname: { type: String, required: true, trim: true },
    department: { type: String, trim: true },
  },
  { timestamps: true }
);

module.exports = model("Instructor", instructorSchema);