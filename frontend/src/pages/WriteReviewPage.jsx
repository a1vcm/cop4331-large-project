import { useEffect, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import Stars from './components/Stars.jsx';
import { getCourseById } from '../api/courses.js';
import { createReview, updateReview } from '../api/reviews.js';
import { getErrorMessage } from '../api/client.js';
import { REVIEW_TAGS } from '../constants/reviewTags.js';
import './WriteReviewPage.css';

const GRADE_OPTIONS = ['', 'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'W', 'P'];
const WORD_LIMIT = 300;

function wordCount(text) {
  const trimmed = text.trim();
  return trimmed === '' ? 0 : trimmed.split(/\s+/).length;
}

function limitWords(text, limit) {
  const words = text.split(/\s+/);
  if (words.length <= limit) return text;
  return words.slice(0, limit).join(' ');
}

// One dedicated page for both creating and editing a review — same
// existing-prop pattern the old inline ReviewForm used.
function WriteReviewPage({ courseId, existing, onCancel, onSaved, onAccountClick }) {
  const [course, setCourse] = useState(null);
  const [quality, setQuality] = useState(existing?.quality ?? 3);
  const [difficulty, setDifficulty] = useState(existing?.difficulty ?? 3);
  const [professorRating, setProfessorRating] = useState(existing?.professorRating ?? 3);
  const [attendance, setAttendance] = useState(existing?.attendance ?? 3);
  const [grade, setGrade] = useState(existing?.grade ?? '');
  const [instructor, setInstructor] = useState(existing?.instructor ?? '');
  const [term, setTerm] = useState(existing?.term ?? '');
  const [comment, setComment] = useState(existing?.comment ?? '');
  const [tags, setTags] = useState(existing?.tags ?? []);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    getCourseById(courseId)
      .then(setCourse)
      .catch(() => {});
  }, [courseId]);

  const toggleTag = (tag) => {
    setTags((prev) => (prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]));
  };

  const handleCommentChange = (e) => {
    setComment(limitWords(e.target.value, WORD_LIMIT));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    const payload = {
      quality,
      difficulty,
      professorRating,
      attendance,
      grade,
      instructor: instructor.trim(),
      term: term.trim(),
      comment: comment.trim(),
      tags,
    };
    try {
      if (existing) {
        await updateReview(existing._id, payload);
      } else {
        await createReview({ courseId, ...payload });
      }
      onSaved();
    } catch (err) {
      setError(getErrorMessage(err, 'Failed to save review.'));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="write-review-page">
      <TopBar showBackButton onBack={onCancel} showCoursesIcon={false} onAccountClick={onAccountClick} fixed />
      <div className="write-review-top-spacer" />

      <div className="write-review-content">
        <h1 className="write-review-heading">
          {existing ? 'Edit Your Review' : 'Write a Review'}
          {course ? ` — ${course.course_code}` : ''}
        </h1>

        <form className="write-review-form" onSubmit={handleSubmit}>
          <div className="write-review-field">
            <span className="write-review-label">Overall Quality</span>
            <div className="write-review-stars-row">
              <Stars value={quality} onChange={setQuality} allowHalf size={32} />
              <span className="write-review-value-readout">{quality.toFixed(1)} / 5.0</span>
            </div>
          </div>

          <div className="write-review-field">
            <span className="write-review-label">Difficulty</span>
            <Stars value={difficulty} onChange={setDifficulty} size={26} />
          </div>

          <div className="write-review-field">
            <span className="write-review-label">Professor Rating</span>
            <Stars value={professorRating} onChange={setProfessorRating} size={26} />
          </div>

          <div className="write-review-field">
            <span className="write-review-label">Attendance (how strictly enforced?)</span>
            <Stars value={attendance} onChange={setAttendance} size={26} />
          </div>

          <label className="write-review-select-label">
            Grade received
            <select value={grade} onChange={(e) => setGrade(e.target.value)}>
              {GRADE_OPTIONS.map((g) => (
                <option key={g || 'none'} value={g}>
                  {g || 'Select grade'}
                </option>
              ))}
            </select>
          </label>

          <input
            type="text"
            placeholder="Instructor (optional)"
            value={instructor}
            onChange={(e) => setInstructor(e.target.value)}
          />
          <input
            type="text"
            placeholder="Term, e.g. Fall 2026 (optional)"
            value={term}
            onChange={(e) => setTerm(e.target.value)}
          />

          <div className="write-review-tags-field">
            <span className="write-review-label">Tags (optional)</span>
            <div className="write-review-tag-options">
              {REVIEW_TAGS.map((tag) => (
                <button
                  type="button"
                  key={tag}
                  className={`tag-chip ${tags.includes(tag) ? 'selected' : ''}`}
                  onClick={() => toggleTag(tag)}
                >
                  {tag}
                </button>
              ))}
            </div>
          </div>

          <div className="write-review-comment-field">
            <textarea
              placeholder="Share your experience — what should someone know before taking this class? (optional)"
              rows={6}
              value={comment}
              onChange={handleCommentChange}
            />
            <span className="write-review-word-count">
              {wordCount(comment)} / {WORD_LIMIT} words
            </span>
          </div>

          {error && <p className="write-review-error">{error}</p>}

          <div className="write-review-actions">
            <button type="button" className="write-review-cancel" onClick={onCancel} disabled={saving}>
              Cancel
            </button>
            <button type="submit" className="write-review-submit" disabled={saving}>
              {saving ? 'Saving…' : existing ? 'Save Changes' : 'Submit Review'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default WriteReviewPage;
