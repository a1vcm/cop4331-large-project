// seed.js
// Loads the UCF Computer Science Department's course catalog (CS and IT
// Required and Electives List, AY2025-2026) into the real `courses`
// collection via the app's own Mongoose model/connection, so search and
// reviews have real data to work against instead of manually-created test
// entries. Idempotent — upserts by course_code, safe to re-run.
//
// Source: https://www.cs.ucf.edu/wp-content/uploads/2026/03/CSIT-Elective-List-AY2025-2026-Updated-on-3-11-26-added-EEL4872-1.pdf
//
// Run with:  node seed.js

require('dotenv').config();
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const { connectDB } = require('./db');
const Course = require('./collections/Course');
const Review = require('./collections/Review');
const User = require('./collections/User');
const { REVIEW_TAGS } = require('./utils/reviewTags');

const COURSES = [
  { course_code: 'CAP4053', title: 'AI for Game Programming', department: 'CAP', credits: 3 },
  { course_code: 'CAP4102', title: 'IT Design and User Experience', department: 'CAP', credits: 3 },
  { course_code: 'CAP4145', title: 'Introduction to Malware Analysis', department: 'CAP', credits: 3 },
  { course_code: 'CAP4314', title: 'Social Network Analysis', department: 'CAP', credits: 3 },
  { course_code: 'CAP4453', title: 'Robot Vision', department: 'CAP', credits: 3 },
  { course_code: 'CAP4543', title: 'Introduction to Bioinformatics Algorithms', department: 'CAP', credits: 3 },
  { course_code: 'CAP4611', title: 'Algorithms for Machine Learning', department: 'CAP', credits: 3 },
  { course_code: 'CAP4630', title: 'Artificial Intelligence', department: 'CAP', credits: 3 },
  { course_code: 'CAP4641', title: 'Natural Language Processing', department: 'CAP', credits: 3 },
  { course_code: 'CAP4720', title: 'Computer Graphics', department: 'CAP', credits: 3 },
  { course_code: 'CAP5115', title: 'Virtual Reality Engineering', department: 'CAP', credits: 3 },
  { course_code: 'CAP5150', title: 'Foundations of Computer Security and Privacy', department: 'CAP', credits: 3 },
  { course_code: 'CAP5415', title: 'Computer Vision', department: 'CAP', credits: 3 },
  { course_code: 'CAP5510', title: 'Bioinformatics', department: 'CAP', credits: 3 },
  { course_code: 'CAP5512', title: 'Evolutionary Computation', department: 'CAP', credits: 3 },
  { course_code: 'CAP5610', title: 'Machine Learning', department: 'CAP', credits: 3 },
  { course_code: 'CAP5636', title: 'Advanced Artificial Intelligence', department: 'CAP', credits: 3 },
  { course_code: 'CAP5725', title: 'Computer Graphics I', department: 'CAP', credits: 3 },
  { course_code: 'CAP5738', title: 'Visualization Techniques for Data Analysis', department: 'CAP', credits: 3 },
  { course_code: 'CDA3103C', title: 'Computer Logic and Organization', department: 'CDA', credits: 3 },
  { course_code: 'CDA5106', title: 'Advanced Computer Architecture', department: 'CDA', credits: 3 },
  { course_code: 'CDA5110', title: 'Parallel Architecture and Algorithms', department: 'CDA', credits: 3 },
  { course_code: 'CEN4360', title: 'Mobile Device Software Development', department: 'CEN', credits: 3 },
  { course_code: 'CEN5016', title: 'Software Engineering', department: 'CEN', credits: 3 },
  { course_code: 'CGS2545C', title: 'Database Concepts', department: 'CGS', credits: 3 },
  { course_code: 'CGS3269', title: 'Computer Architecture Concepts', department: 'CGS', credits: 3 },
  { course_code: 'CGS3763', title: 'Operating System Concepts', department: 'CGS', credits: 3 },
  { course_code: 'CIS3003', title: 'Fundamentals of Information Technology', department: 'CIS', credits: 3 },
  { course_code: 'CIS3360', title: 'Security in Computing', department: 'CIS', credits: 3 },
  { course_code: 'CIS3362', title: 'Cryptography and Information Security', department: 'CIS', credits: 3 },
  { course_code: 'CIS3921', title: 'Careers in IT', department: 'CIS', credits: 1 },
  { course_code: 'CIS3990', title: 'IT Career and Academic Advising I', department: 'CIS', credits: 0 },
  { course_code: 'CIS4004', title: 'Web-Based Information Technology', department: 'CIS', credits: 3 },
  { course_code: 'CIS4203C', title: 'Digital Forensics', department: 'CIS', credits: 3 },
  { course_code: 'CIS4361', title: 'Secure Operating Systems and Administration', department: 'CIS', credits: 3 },
  { course_code: 'CIS4364', title: 'Cyber Defense Analysis', department: 'CIS', credits: 3 },
  { course_code: 'CIS4524', title: 'Managing IT Integration', department: 'CIS', credits: 3 },
  { course_code: 'CIS4615', title: 'Secure Software Development and Assurance', department: 'CIS', credits: 3 },
  { course_code: 'CIS4940C', title: 'Topics in Cybersecurity', department: 'CIS', credits: 3 },
  { course_code: 'CIS4991', title: 'IT Career and Academic Advising II', department: 'CIS', credits: 0 },
  { course_code: 'CNT3004', title: 'Computer Network Concepts', department: 'CNT', credits: 3 },
  { course_code: 'CNT4403', title: 'Network Security and Privacy', department: 'CNT', credits: 3 },
  { course_code: 'CNT4425', title: 'Cloud Computing Management', department: 'CNT', credits: 3 },
  { course_code: 'CNT4603', title: 'System Administration and Maintenance', department: 'CNT', credits: 3 },
  { course_code: 'CNT4703C', title: 'Design & Implementation of Comp Comm Network', department: 'CNT', credits: 3 },
  { course_code: 'CNT4704', title: 'Analysis of Computer Communication Networks', department: 'CNT', credits: 3 },
  { course_code: 'CNT4714', title: 'Enterprise Computing', department: 'CNT', credits: 3 },
  { course_code: 'CNT5008', title: 'Computer Communication Networks Architecture', department: 'CNT', credits: 3 },
  { course_code: 'CNT5805', title: 'Network Science', department: 'CNT', credits: 3 },
  { course_code: 'COP3223C', title: 'Introduction to Programming with C', department: 'COP', credits: 3 },
  { course_code: 'COP3330', title: 'Object Oriented Programming', department: 'COP', credits: 3 },
  { course_code: 'COP3402', title: 'Systems Software', department: 'COP', credits: 3 },
  { course_code: 'COP3502C', title: 'Computer Science I', department: 'COP', credits: 3 },
  { course_code: 'COP3503C', title: 'Computer Science II', department: 'COP', credits: 3 },
  { course_code: 'COP4020', title: 'Programming Languages I', department: 'COP', credits: 3 },
  { course_code: 'COP4283', title: 'Data Science Programming', department: 'COP', credits: 3 },
  { course_code: 'COP4331C', title: 'Processes for Object-Oriented Software Development', department: 'COP', credits: 3 },
  { course_code: 'COP4516C', title: 'Problem Solving Techniques and Team Dynamics', department: 'COP', credits: 3 },
  { course_code: 'COP4520', title: 'Concepts of Parallel and Distributed Processing', department: 'COP', credits: 3 },
  { course_code: 'COP4600', title: 'Operating Systems', department: 'COP', credits: 3 },
  { course_code: 'COP4710', title: 'Database Systems', department: 'COP', credits: 3 },
  { course_code: 'COP4910', title: 'Frontiers in Information Technology', department: 'COP', credits: 3 },
  { course_code: 'COP4934', title: 'Senior Design I', department: 'COP', credits: 3 },
  { course_code: 'COP4935', title: 'Senior Design II', department: 'COP', credits: 3 },
  { course_code: 'COP4941', title: 'Approved CS Internship Experience', department: 'COP', credits: 3 },
  { course_code: 'COP5021', title: 'Program Analysis', department: 'COP', credits: 3 },
  { course_code: 'COP5537', title: 'Network Optimization', department: 'COP', credits: 3 },
  { course_code: 'COP5611', title: 'Operating Systems Design Principles', department: 'COP', credits: 3 },
  { course_code: 'COP5621', title: 'Compiler Construction', department: 'COP', credits: 3 },
  { course_code: 'COP5711', title: 'Parallel and Distributed Database Systems', department: 'COP', credits: 3 },
  { course_code: 'COT3100C', title: 'Introduction to Discrete Structures', department: 'COT', credits: 3 },
  { course_code: 'COT4210', title: 'Discrete Structures II', department: 'COT', credits: 3 },
  { course_code: 'COT4400', title: 'Tools for Algorithm Analysis', department: 'COT', credits: 3 },
  { course_code: 'COT4500', title: 'Numerical Calculus', department: 'COT', credits: 3 },
  { course_code: 'COT5405', title: 'Design and Analysis of Algorithms', department: 'COT', credits: 3 },
  { course_code: 'COT5600', title: 'Quantum Computing', department: 'COT', credits: 3 },
  { course_code: 'EEE4346C', title: 'Hardware Security and Trusted Circuit Design', department: 'EEE', credits: 3 },
  { course_code: 'EEL4660', title: 'Robotic Systems', department: 'EEL', credits: 3 },
  { course_code: 'EEL4768', title: 'Computer Architecture', department: 'EEL', credits: 3 },
  { course_code: 'EEL4781', title: 'Computer Communication Networks', department: 'EEL', credits: 3 },
  { course_code: 'EEL4872', title: 'Engineering Applications of Intelligent System', department: 'EEL', credits: 3 },
  { course_code: 'EEL5780', title: 'Wireless Networks', department: 'EEL', credits: 3 },
  { course_code: 'EEL5820', title: 'Image Processing', department: 'EEL', credits: 3 },
  { course_code: 'EGN4060C', title: 'Introduction to Robotics', department: 'EGN', credits: 3 },
  { course_code: 'EGN4630', title: 'Entrepreneurship for Defense', department: 'EGN', credits: 3 },
  { course_code: 'EGN4641', title: 'Engineering Entrepreneurship', department: 'EGN', credits: 3 },
  { course_code: 'EGN5640', title: 'Entrepreneurship for Defense', department: 'EGN', credits: 3 },
  { course_code: 'MAP4384', title: 'Numerical Methods for Computational Sciences', department: 'MAP', credits: 3 },
  { course_code: 'PHY3650', title: 'Quantum Information Processing', department: 'PHY', credits: 3 },

  // General education & common program prerequisites shared by CS/IT majors
  // (confirmed against a real degree audit + the official CS flowchart/GEP
  // worksheet — see conversation history, not fabricated).
  { course_code: 'ENC1101', title: 'English Composition I', department: 'ENC', credits: 3 },
  { course_code: 'ENC1102', title: 'English Composition II', department: 'ENC', credits: 3 },
  { course_code: 'ENC3250', title: 'Technical Report Writing', department: 'ENC', credits: 3 },
  { course_code: 'MAC1105C', title: 'College Algebra', department: 'MAC', credits: 3 },
  { course_code: 'MAC1114', title: 'Trigonometry', department: 'MAC', credits: 3 },
  { course_code: 'MAC1140', title: 'Precalculus Algebra', department: 'MAC', credits: 3 },
  { course_code: 'MAC2311C', title: 'Calculus with Analytic Geometry I', department: 'MAC', credits: 4 },
  { course_code: 'MAC2312', title: 'Calculus with Analytic Geometry II', department: 'MAC', credits: 4 },
  { course_code: 'MAC2313', title: 'Calculus with Analytic Geometry III', department: 'MAC', credits: 4 },
  { course_code: 'STA2023', title: 'Statistical Methods I', department: 'STA', credits: 3 },
  { course_code: 'PHY2048', title: 'General Physics Using Calculus I', department: 'PHY', credits: 3 },
  { course_code: 'PHY2048L', title: 'General Physics Using Calculus I Lab', department: 'PHY', credits: 1 },
  { course_code: 'PHY2049', title: 'General Physics Using Calculus II', department: 'PHY', credits: 3 },
  { course_code: 'PHY2049L', title: 'General Physics Using Calculus II Lab', department: 'PHY', credits: 1 },
  { course_code: 'MAP2302', title: 'Elementary Differential Equations', department: 'MAP', credits: 3 },
  { course_code: 'MAS3105', title: 'Matrix and Linear Algebra', department: 'MAS', credits: 4 },
  { course_code: 'BSC2010C', title: 'Biology I', department: 'BSC', credits: 4 },
  { course_code: 'BSC2011C', title: 'Biology II', department: 'BSC', credits: 4 },
  { course_code: 'CHM2045C', title: 'Chemistry Fundamentals I', department: 'CHM', credits: 4 },
];

// ---------------------------------------------------------------------------
// Demo reviews — synthetic, clearly-fictional accounts only, never scraped
// or attributed to real people. Only ever applied to courses that have zero
// reviews, so this is safe to re-run: once a course has been touched it's
// never touched again, and nothing here overwrites a real user's review.

const SEED_REVIEWER_POOL = [
  { username: 'midnightknight', email: 'seed.midnightknight@example.com' },
  { username: 'starlit_pegasus', email: 'seed.starlitpegasus@example.com' },
  { username: 'quillandquad', email: 'seed.quillandquad@example.com' },
  { username: 'orlando_owl', email: 'seed.orlandoowl@example.com' },
  { username: 'senior_knight24', email: 'seed.seniorknight24@example.com' },
  { username: 'goldenpaladin', email: 'seed.goldenpaladin@example.com' },
  { username: 'campuscoder', email: 'seed.campuscoder@example.com' },
  { username: 'librarylurker', email: 'seed.librarylurker@example.com' },
  { username: 'latenightlab', email: 'seed.latenightlab@example.com' },
  { username: 'quizbowlqueen', email: 'seed.quizbowlqueen@example.com' },
  { username: 'footballfanatic', email: 'seed.footballfanatic@example.com' },
  { username: 'thesisthinker', email: 'seed.thesisthinker@example.com' },
];

const SEED_INSTRUCTORS = [
  'Dr. Alaric Stone', 'Prof. Priya Anand', 'Dr. Marcus Whitfield', 'Prof. Elena Castillo',
  'Dr. Samuel Voss', 'Prof. Naomi Reyes', 'Dr. Owen Baptiste', 'Prof. Mei Lin Chao',
];

const SEED_TERMS = ['Fall 2025', 'Spring 2026', 'Summer 2025', 'Fall 2024', 'Spring 2025'];
const SEED_GRADES = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C'];

// Sentence-fragment pools, combined per review so no two reads identically.
const SEED_OPENERS = [
  'Took this course last term and overall it was worth it.',
  'Honestly went in with low expectations and was pleasantly surprised.',
  "This one's a staple for the major, so plan ahead.",
  'Solid class if you keep up with the material week to week.',
  'Wasn\'t my favorite, but I learned a lot by the end.',
  'Would recommend to anyone who likes a structured workload.',
];
const SEED_MIDDLES = [
  'Lectures moved at a reasonable pace and slides were posted ahead of time.',
  'Assignments took longer than expected, so budget extra hours.',
  'Office hours were genuinely useful — worth showing up to.',
  'Exams closely followed the homework, no surprises there.',
  'Group work was a big chunk of the grade, so pick your team wisely.',
  'Grading felt fair as long as you followed the rubric closely.',
];
const SEED_CLOSERS = [
  'Would take again if I had the choice.',
  'Not the easiest course, but manageable if you stay organized.',
  'Glad I got it out of the way early.',
  'Definitely helped with the courses that came after it.',
  "Wouldn't call it fun, but it was fair.",
  'Solid class overall — no regrets taking it.',
];

function pickN(arr, n) {
  const copy = [...arr];
  const out = [];
  for (let i = 0; i < n && copy.length > 0; i += 1) {
    out.push(copy.splice(Math.floor(Math.random() * copy.length), 1)[0]);
  }
  return out;
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

// Half-star increments only, matching the Review schema's quality validator.
function randomHalfStar(min = 2, max = 5) {
  const steps = (max - min) * 2;
  return min + Math.round(Math.random() * steps) / 2;
}

function randomWholeStar(min = 2, max = 5) {
  return min + Math.floor(Math.random() * (max - min + 1));
}

async function ensureSeedReviewers() {
  const passwordHash = await bcrypt.hash('SeedAccount!Not-A-Real-Login', 10);
  const users = [];
  for (const r of SEED_REVIEWER_POOL) {
    const user = await User.findOneAndUpdate(
      { email: r.email },
      { $setOnInsert: { username: r.username, email: r.email, passwordHash, isVerified: true } },
      { upsert: true, returnDocument: 'after' }
    );
    users.push(user);
  }
  return users;
}

async function recalcCourseStats(courseId) {
  const stats = await Review.aggregate([
    { $match: { courseId: new mongoose.Types.ObjectId(courseId) } },
    {
      $group: {
        _id: '$courseId',
        numRatings: { $sum: 1 },
        avgRating: { $avg: '$quality' },
        avgDifficulty: { $avg: '$difficulty' },
      },
    },
  ]);
  if (stats.length > 0) {
    await Course.findByIdAndUpdate(courseId, {
      numRatings: stats[0].numRatings,
      avgRating: Math.round(stats[0].avgRating * 10) / 10,
      avgDifficulty: Math.round(stats[0].avgDifficulty * 10) / 10,
      lastReviewedAt: new Date(),
    });
  }
}

async function seedReviews() {
  const reviewers = await ensureSeedReviewers();
  const unreviewedCourses = [];
  for (const course of await Course.find({})) {
    // eslint-disable-next-line no-await-in-loop
    const count = await Review.countDocuments({ courseId: course._id });
    if (count === 0) unreviewedCourses.push(course);
  }

  console.log(`[seed] ${unreviewedCourses.length} course(s) have zero reviews — adding synthetic demo reviews...`);

  let totalAdded = 0;
  for (const course of unreviewedCourses) {
    const n = 2 + Math.floor(Math.random() * 4); // 2-5 reviews
    const reviewAuthors = pickN(reviewers, Math.min(n, reviewers.length));
    for (const author of reviewAuthors) {
      const comment = `${pick(SEED_OPENERS)} ${pick(SEED_MIDDLES)} ${pick(SEED_CLOSERS)}`;
      // eslint-disable-next-line no-await-in-loop
      await Review.create({
        courseId: course._id,
        userId: author._id,
        instructor: pick(SEED_INSTRUCTORS),
        term: pick(SEED_TERMS),
        quality: randomHalfStar(2, 5),
        difficulty: randomWholeStar(1, 5),
        workload: randomWholeStar(1, 5),
        gradingFairness: randomWholeStar(2, 5),
        professorRating: randomWholeStar(2, 5),
        attendance: randomWholeStar(1, 5),
        grade: pick(SEED_GRADES),
        comment,
        tags: pickN(REVIEW_TAGS, Math.floor(Math.random() * 3)),
      });
      totalAdded += 1;
    }
    // eslint-disable-next-line no-await-in-loop
    await recalcCourseStats(course._id);
  }

  console.log(`[seed] Added ${totalAdded} synthetic review(s) across ${unreviewedCourses.length} course(s).`);
}

async function seed() {
  await connectDB();
  console.log(`[seed] Upserting ${COURSES.length} courses...`);

  let created = 0;
  let updated = 0;
  for (const course of COURSES) {
    const res = await Course.updateOne(
      { course_code: course.course_code },
      { $setOnInsert: course },
      { upsert: true }
    );
    if (res.upsertedCount > 0) created++;
    else updated++;
  }

  console.log(`[seed] Done. ${created} created, ${updated} already existed.`);
  console.log(`[seed] Total courses in database: ${await Course.countDocuments()}`);

  await seedReviews();

  process.exit(0);
}

seed().catch((err) => {
  console.error('[seed] Error:', err.message);
  process.exit(1);
});
