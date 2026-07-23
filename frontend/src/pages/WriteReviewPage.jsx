import { useEffect, useMemo, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import Stars from './components/Stars.jsx';
import { getCourseById } from '../api/courses.js';
import { createReview, updateReview } from '../api/reviews.js';
import { createResource } from '../api/resources.js';
import { getErrorMessage } from '../api/client.js';
import { REVIEW_TAGS } from '../constants/reviewTags.js';
import './WriteReviewPage.css';

const GRADE_OPTIONS = ['', 'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'W', 'P'];
const CHAR_LIMIT = 500;
const TERMS = ['Spring', 'Summer', 'Fall'];

function buildTermOptions(existingTerm) {
  const year = new Date().getFullYear();
  const options = [];
  for (let y = year + 1; y >= year - 2; y -= 1) {
    for (let i = TERMS.length - 1; i >= 0; i -= 1) {
      options.push(`${TERMS[i]} ${y}`);
    }
  }
  if (existingTerm && !options.includes(existingTerm)) {
    options.unshift(existingTerm);
  }
  return options;
}

// One dedicated page for both creating and editing a review — same
// existing-prop pattern the old inline ReviewForm used.
function WriteReviewPage({ courseId, existing, onCancel, onSaved, onAccountClick, onViewResources, onLogoClick }) {
  const [course, setCourse] = useState(null);
  const [quality, setQuality] = useState(existing?.quality ?? 3);
  const [difficulty, setDifficulty] = useState(existing?.difficulty ?? 3);
  const [workload, setWorkload] = useState(existing?.workload ?? 3);
  const [gradingFairness, setGradingFairness] = useState(existing?.gradingFairness ?? 3);
  const [professorRating, setProfessorRating] = useState(existing?.professorRating ?? 3);
  const [attendance, setAttendance] = useState(existing?.attendance ?? 3);
  const [grade, setGrade] = useState(existing?.grade ?? '');
  const [instructor, setInstructor] = useState(existing?.instructor ?? '');
  const [term, setTerm] = useState(existing?.term ?? '');
  const [comment, setComment] = useState(existing?.comment ?? '');
  const [tags, setTags] = useState(existing?.tags ?? []);
  const [showResourceForm, setShowResourceForm] = useState(false);
  const [resourceTitle, setResourceTitle] = useState('');
  const [resourceUrl, setResourceUrl] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [fieldErrors, setFieldErrors] = useState({ term: false, comment: false });

  const termOptions = useMemo(() => buildTermOptions(existing?.term), [existing?.term]);

  useEffect(() => {
    getCourseById(courseId)
      .then(setCourse)
      .catch(() => {});
  }, [courseId]);

  const toggleTag = (tag) => {
    setTags((prev) => (prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Term and comment aren't required by the database, but a review with
    // neither is useless to other students — warn instead of silently
    // accepting it.
    const nextFieldErrors = {
      term: !term,
      comment: !comment.trim(),
    };
    if (nextFieldErrors.term || nextFieldErrors.comment) {
      setFieldErrors(nextFieldErrors);
      setError('Please fill out the required fields highlighted below.');
      return;
    }
    setFieldErrors({ term: false, comment: false });

    setSaving(true);
    setError(null);
    const payload = {
      quality,
      difficulty,
      workload,
      gradingFairness,
      professorRating,
      attendance,
      grade,
      instructor: instructor.trim(),
      term,
      comment: comment.trim(),
      tags,
    };
    try {
      if (existing) {
        await updateReview(existing._id, payload);
      } else {
        await createReview({ courseId, ...payload });
      }
      if (resourceTitle.trim() && resourceUrl.trim()) {
        await createResource({ courseId, title: resourceTitle.trim(), url: resourceUrl.trim() }).catch(() => {});
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
      <TopBar
        showBackButton
        onBack={onCancel}
        onLogoClick={onLogoClick}
        showCoursesIcon={false}
        onAccountClick={onAccountClick}
        fixed
      />
      <div className="write-review-top-spacer" />

      <div className="write-review-content">
        <h1 className="write-review-heading">Rate the Course</h1>

        <form className="write-review-form" onSubmit={handleSubmit}>
          <div className="course-info-card">
            <div className="course-info-avatar" aria-hidden="true" />
            <div className="course-info-main">
              <span className="course-info-title">
                {course ? `${course.course_code} - ${course.title}` : 'Loading course…'}
              </span>
              <input
                type="text"
                className="course-info-instructor"
                placeholder="Prof. name (optional)"
                value={instructor}
                onChange={(e) => setInstructor(e.target.value)}
              />
            </div>
            <div className="course-info-side">
              <select
                value={term}
                className={fieldErrors.term ? 'field-invalid' : ''}
                onChange={(e) => {
                  setTerm(e.target.value);
                  if (e.target.value) setFieldErrors((prev) => ({ ...prev, term: false }));
                }}
              >
                <option value="">Select term</option>
                {termOptions.map((t) => (
                  <option key={t} value={t}>
                    {t}
                  </option>
                ))}
              </select>
              {fieldErrors.term && <p className="write-review-field-error">Term is required.</p>}
              {onViewResources && (
                <button
                  type="button"
                  className="course-info-syllabus"
                  onClick={() => onViewResources(courseId)}
                >
                  Syllabus
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M10 13a5 5 0 0 0 7.07 0l2.83-2.83a5 5 0 0 0-7.07-7.07L11.5 4.5" />
                    <path d="M14 11a5 5 0 0 0-7.07 0L4.1 13.83a5 5 0 0 0 7.07 7.07L12.5 19.5" />
                  </svg>
                </button>
              )}
            </div>
          </div>

          <div className="write-review-field">
            <span className="write-review-label">Overall Rating</span>
            <div className="write-review-stars-row">
              <Stars value={quality} onChange={setQuality} allowHalf size={32} />
              <span className="write-review-value-readout">{quality.toFixed(1)} / 5.0</span>
            </div>
          </div>

          <div className="rating-grid">
            <div className="rating-grid-row">
              <span>Difficulty</span>
              <Stars value={difficulty} onChange={setDifficulty} size={20} />
            </div>
            <div className="rating-grid-row">
              <span>Workload</span>
              <Stars value={workload} onChange={setWorkload} size={20} />
            </div>
            <div className="rating-grid-row">
              <span>Grading Fairness</span>
              <Stars value={gradingFairness} onChange={setGradingFairness} size={20} />
            </div>
            <div className="rating-grid-row">
              <span>Professor Quality</span>
              <Stars value={professorRating} onChange={setProfessorRating} size={20} />
            </div>
          </div>

          <div className="write-review-field">
            <span className="write-review-label">Attendance (how strictly enforced, optional)</span>
            <Stars value={attendance} onChange={setAttendance} size={20} />
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

          <div className="attach-resources-field">
            <span className="write-review-label">Attach Resources</span>
            {!showResourceForm ? (
              <button
                type="button"
                className="attach-resources-btn"
                onClick={() => setShowResourceForm(true)}
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M10 13a5 5 0 0 0 7.07 0l2.83-2.83a5 5 0 0 0-7.07-7.07L11.5 4.5" />
                  <path d="M14 11a5 5 0 0 0-7.07 0L4.1 13.83a5 5 0 0 0 7.07 7.07L12.5 19.5" />
                </svg>
                Attach File, Link, or Document
              </button>
            ) : (
              <div className="attach-resources-form">
                <input
                  type="text"
                  placeholder="Title, e.g. Course syllabus"
                  value={resourceTitle}
                  onChange={(e) => setResourceTitle(e.target.value)}
                  maxLength={120}
                />
                <input
                  type="url"
                  placeholder="https://…"
                  value={resourceUrl}
                  onChange={(e) => setResourceUrl(e.target.value)}
                />
                <button
                  type="button"
                  className="attach-resources-cancel"
                  onClick={() => {
                    setShowResourceForm(false);
                    setResourceTitle('');
                    setResourceUrl('');
                  }}
                >
                  Remove
                </button>
              </div>
            )}
          </div>

          <div className="write-review-tags-field">
            <span className="write-review-label">Add Tags</span>
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
            <span className="write-review-label">
              Write a Review<span className="required-asterisk">*</span>
            </span>
            <textarea
              placeholder="Share your experience with this course…."
              rows={6}
              value={comment}
              maxLength={CHAR_LIMIT}
              className={fieldErrors.comment ? 'field-invalid' : ''}
              onChange={(e) => {
                setComment(e.target.value);
                if (e.target.value.trim()) setFieldErrors((prev) => ({ ...prev, comment: false }));
              }}
            />
            <span className="write-review-word-count">
              {comment.length} / {CHAR_LIMIT}
            </span>
            {fieldErrors.comment && <p className="write-review-field-error">A review comment is required.</p>}
          </div>

          {error && <p className="write-review-error">{error}</p>}

          <div className="write-review-actions">
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
