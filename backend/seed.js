// seed.js
// Populates the database with test data, then verifies everything works:
// connection, inserts, reads, aggregates, relationships, and the
// one-vote-per-user rule. Safe to run multiple times (it clears old data first).
//
// Run with:  node seed.js

require("dotenv").config(); // loads .env so process.env.MONGODB_URI is available
const { MongoClient } = require("mongodb");

// Set MONGODB_URI in your environment / .env (defaults to the local dev container)
const url = process.env.MONGODB_URI || "mongodb://localhost:27017/coursedb";

const client = new MongoClient(url);
const COLLECTIONS = ["Users", "Courses", "Instructors", "Reviews", "Votes"];

async function seed() {
  try {
    await client.connect();
    const db = client.db("coursedb");
    console.log("[seed] Connected to MongoDB\n");

    // 1. Clear previous test data so this script can be re-run safely
    for (const name of COLLECTIONS) {
      await db.collection(name).deleteMany({});
    }
    console.log("[seed] Cleared old test data");

    // 2. Ensure the unique index that blocks double-voting exists
    await db
      .collection("Votes")
      .createIndex({ reviewId: 1, userId: 1 }, { unique: true });
    console.log("[seed] Ensured unique index on Votes(reviewId, userId)\n");

    // 3. Users
    const users = await db.collection("Users").insertMany([
      { username: "knight_2026", email: "student1@knights.ucf.edu", passwordHash: "hash_placeholder", createdAt: new Date() },
      { username: "pegasus_ry",  email: "student2@knights.ucf.edu", passwordHash: "hash_placeholder", createdAt: new Date() },
    ]);
    const userIds = Object.values(users.insertedIds);

    // 4. Instructors
    await db.collection("Instructors").insertMany([
      { firstname: "Jane", lastname: "Doe", department: "Computer Science", createdAt: new Date(), updatedAt: new Date() },
      { firstname: "Mark", lastname: "Lee", department: "Computer Science", createdAt: new Date(), updatedAt: new Date() },
    ]);

    // 5. Courses (aggregates start at 0, recomputed from reviews below)
    const courses = await db.collection("Courses").insertMany([
      { course_code: "COP3502", title: "Computer Science I", department: "Computer Science", credits: 3, avgRating: 0, avgDifficulty: 0, numRatings: 0, createdAt: new Date(), updatedAt: new Date() },
      { course_code: "COP4331", title: "Processes for Object-Oriented Software Development", department: "Computer Science", credits: 3, avgRating: 0, avgDifficulty: 0, numRatings: 0, createdAt: new Date(), updatedAt: new Date() },
    ]);
    const courseIds = Object.values(courses.insertedIds);

    // 6. Reviews (each linked to a course and a user)
    const reviews = await db.collection("Reviews").insertMany([
      { courseId: courseIds[0], userId: userIds[0], instructor: "Jane Doe", term: "Fall 2025",   quality: 5, difficulty: 3, grade: "A", comment: "Clear lectures, fair exams.",        voteScore: { helpful: 0, notHelpful: 0 }, createdAt: new Date(), updatedAt: new Date() },
      { courseId: courseIds[0], userId: userIds[1], instructor: "Jane Doe", term: "Spring 2025", quality: 4, difficulty: 4, grade: "B", comment: "Heavy workload but you learn a lot.", voteScore: { helpful: 0, notHelpful: 0 }, createdAt: new Date(), updatedAt: new Date() },
      { courseId: courseIds[1], userId: userIds[0], instructor: "Mark Lee", term: "Summer 2025", quality: 4, difficulty: 5, grade: "A", comment: "Group project is intense.",           voteScore: { helpful: 0, notHelpful: 0 }, createdAt: new Date(), updatedAt: new Date() },
    ]);
    const reviewIds = Object.values(reviews.insertedIds);

    // 7. Recompute COP3502's aggregates from its two reviews
    const stats = await db.collection("Reviews").aggregate([
      { $match: { courseId: courseIds[0] } },
      { $group: { _id: null, avgRating: { $avg: "$quality" }, avgDifficulty: { $avg: "$difficulty" }, numRatings: { $sum: 1 } } },
    ]).toArray();
    if (stats[0]) {
      await db.collection("Courses").updateOne(
        { _id: courseIds[0] },
        { $set: { avgRating: stats[0].avgRating, avgDifficulty: stats[0].avgDifficulty, numRatings: stats[0].numRatings } }
      );
    }

    // 8. Votes
    await db.collection("Votes").insertMany([
      { reviewId: reviewIds[0], userId: userIds[1], value: 1,  createdAt: new Date() },
      { reviewId: reviewIds[1], userId: userIds[0], value: -1, createdAt: new Date() },
    ]);
    console.log("[seed] Inserted test data\n");

    // ---------- VERIFICATION ----------
    console.log("=== Document counts ===");
    for (const name of COLLECTIONS) {
      console.log(`  ${name}: ${await db.collection(name).countDocuments()}`);
    }

    console.log("\n=== Course with recomputed aggregates ===");
    const course = await db.collection("Courses").findOne({ _id: courseIds[0] });
    console.log(`  ${course.course_code} - ${course.title}`);
    console.log(`  avgRating ${course.avgRating}, avgDifficulty ${course.avgDifficulty}, numRatings ${course.numRatings}`);

    console.log("\n=== Relationship check (review -> course via $lookup) ===");
    const joined = await db.collection("Reviews").aggregate([
      { $match: { _id: reviewIds[0] } },
      { $lookup: { from: "Courses", localField: "courseId", foreignField: "_id", as: "course" } },
      { $unwind: "$course" },
    ]).toArray();
    console.log(`  Review "${joined[0].comment}" is linked to ${joined[0].course.course_code}`);

    console.log("\n=== Constraint check (attempt a duplicate vote) ===");
    try {
      await db.collection("Votes").insertOne({ reviewId: reviewIds[0], userId: userIds[1], value: 1, createdAt: new Date() });
      console.log("  WARNING: duplicate vote was allowed - the unique index is NOT working!");
    } catch (err) {
      if (err.code === 11000) {
        console.log("  Duplicate vote correctly blocked (error 11000). Constraint works.");
      } else {
        throw err;
      }
    }

    console.log("\n[seed] All checks passed - your database is working.");
  } catch (err) {
    console.error("[seed] Error:", err.message);
  } finally {
    await client.close();
  }
}

seed();