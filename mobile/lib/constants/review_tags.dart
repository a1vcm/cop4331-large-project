/// Fixed vocabulary of badges a reviewer can attach to their review.
/// Mirrors backend/utils/reviewTags.js / frontend/src/constants/reviewTags.js
/// exactly — the backend schema enum-validates against this list.
const List<String> kReviewTags = [
  'Would Take Again',
  "Skip Class? Won't Pass",
  'Tough Grader',
  'Easy A',
  'Get Ready To Read',
  'Lots Of Homework',
  'Group Projects',
  'Participation Matters',
  'Extra Credit Available',
  'Test Heavy',
  'Accessible Outside Class',
  'Amazing Lectures',
];
