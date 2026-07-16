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
const { connectDB } = require('./db');
const Course = require('./collections/Course');

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
  { course_code: 'CIS4941', title: 'Approved IT Internship Experience', department: 'CIS', credits: 3 },
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
  { course_code: 'COT3960', title: 'Passed CS Foundation Exam', department: 'COT', credits: 0 },
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
];

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
  process.exit(0);
}

seed().catch((err) => {
  console.error('[seed] Error:', err.message);
  process.exit(1);
});
