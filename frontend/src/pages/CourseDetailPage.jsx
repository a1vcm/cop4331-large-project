import { useEffect, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import { getCourseById } from '../api/courses.js';
import { getCourseReviews, createReview, updateReview, deleteReview } from '../api/reviews.js';
import { getErrorMessage, getAuthUser, isLoggedIn } from '../api/client.js';
import './CourseDetailPage.css';

const DIFFICULTY = {
  easy: { label: 'Easy', color: '#7FCB8F' },
  medium: { label: 'Medium', color: '#F2D14A' },
  hard: { label: 'Hard', color: '#E57373' },
  unrated: { label: 'Not yet rated', color: '#D9D9D9' },
};

function getDifficultyKey(course) {
  if (!course.numRatings) return 'unrated';
  if (course.avgDifficulty <= 2) return 'easy';
  if (course.avgDifficulty <= 3.5) return 'medium';
  return 'hard';
}

function Stars({ value, onChange }) {
  return (
    <div className="star-picker">
      {[1, 2, 3, 4, 5].map((n) => (
        <button
          type="button"
          key={n}
          className={`star-btn ${n <= value ? 'filled' : ''}`}
          onClick={() => onChange(n)}
          aria-label={`${n} star${n === 1 ? '' : 's'}`}
        >
          ★
        </button>
      ))}
    </div>
  );
}

function ReviewForm({ courseId, existing, onCancel, onSaved }) {
  const [quality, setQuality] = useState(existing?.quality ?? 3);
  const [difficulty, setDifficulty] = useState(existing?.difficulty ?? 3);
  const [instructor, setInstructor] = useState(existing?.instructor ?? '');
  const [term, setTerm] = useState(existing?.term ?? '');
  const [grade, setGrade] = useState(existing?.grade ?? '');
  const [comment, setComment] = useState(existing?.comment ?? '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    const payload = {
      instructor: instructor.trim(),
      term: term.trim(),
      quality,
      difficulty,
      grade: grade.trim(),
      comment: comment.trim(),
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
    <form className="review-form" onSubmit={handleSubmit}>
      <h3 className="review-form-heading">{existing ? 'Edit Your Review' : 'Write a Review'}</h3>

      <div className="review-form-row">
        <span className="review-form-label">Quality</span>
        <Stars value={quality} onChange={setQuality} />
      </div>
      <div className="review-form-row">
        <span className="review-form-label">Difficulty</span>
        <Stars value={difficulty} onChange={setDifficulty} />
      </div>

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
      <input
        type="text"
        placeholder="Grade received (optional)"
        value={grade}
        onChange={(e) => setGrade(e.target.value)}
      />
      <textarea
        placeholder="Comments (optional)"
        maxLength={1000}
        rows={4}
        value={comment}
        onChange={(e) => setComment(e.target.value)}
      />

      {error && <p className="review-form-error">{error}</p>}

      <div className="review-form-actions">
        <button type="button" className="review-form-cancel" onClick={onCancel} disabled={saving}>
          Cancel
        </button>
        <button type="submit" className="review-form-submit" disabled={saving}>
          {saving ? 'Saving…' : existing ? 'Save Changes' : 'Submit Review'}
        </button>
      </div>
    </form>
  );
}

function CourseDetailPage({ courseId, onBack, onAccountClick }) {
  const [course, setCourse] = useState(null);
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [formMode, setFormMode] = useState(null); // null | 'new' | review object being edited

  const currentUser = getAuthUser();

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const [courseData, reviewData] = await Promise.all([
        getCourseById(courseId),
        getCourseReviews(courseId),
      ]);
      setCourse(courseData);
      setReviews(reviewData);
    } catch (err) {
      setError(getErrorMessage(err, 'Failed to load this course.'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- initial data fetch on mount
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId]);

  const myReview = currentUser
    ? reviews.find((r) => (r.userId?._id ?? r.userId) === currentUser.id)
    : null;

  const handleDelete = async (review) => {
    if (!window.confirm("Delete this review? This can't be undone.")) return;
    try {
      await deleteReview(review._id);
      load();
    } catch (err) {
      setError(getErrorMessage(err, 'Failed to delete review.'));
    }
  };

  const diffKey = course ? getDifficultyKey(course) : 'unrated';
  const diff = DIFFICULTY[diffKey];

  return (
    <div className="course-detail-page">
      <TopBar
        showBackButton
        onBack={onBack}
        showCoursesIcon={false}
        onAccountClick={onAccountClick}
        fixed
      />
      <div className="course-detail-top-spacer" />

      <div className="course-detail-content">
        {loading && <p className="results-count">Loading course…</p>}
        {error && <p className="results-count">{error}</p>}

        {!loading && !error && course && (
          <>
            <div className="course-header-card">
              <h1 className="course-header-title">{course.title}</h1>
              <p className="course-header-meta">
                {course.course_code}
                {course.department ? ` • ${course.department}` : ''}
                {course.credits ? ` • ${course.credits} credits` : ''}
              </p>
              <div className="course-stats-row">
                <div className="course-stat">
                  <span className="course-stat-value">
                    {course.numRatings === 0 ? '—' : course.avgRating.toFixed(1)}
                  </span>
                  <span className="course-stat-label">Rating</span>
                </div>
                <div className="course-stat">
                  <span className="course-stat-value">
                    {course.numRatings === 0 ? '—' : course.avgDifficulty.toFixed(1)}
                  </span>
                  <span className="course-stat-label">Difficulty</span>
                </div>
                <div className="course-stat">
                  <span className="course-stat-value">{course.numRatings}</span>
                  <span className="course-stat-label">Reviews</span>
                </div>
                <span className="difficulty-badge" style={{ backgroundColor: diff.color }}>
                  {diff.label}
                </span>
              </div>
            </div>

            <div className="reviews-header-row">
              <h2 className="reviews-heading">Reviews ({reviews.length})</h2>
              {!isLoggedIn() ? (
                <button type="button" className="review-link-btn" onClick={onAccountClick}>
                  Log in to review
                </button>
              ) : (
                !myReview &&
                formMode !== 'new' && (
                  <button type="button" className="review-link-btn primary" onClick={() => setFormMode('new')}>
                    Write a Review
                  </button>
                )
              )}
            </div>

            {formMode === 'new' && (
              <ReviewForm
                courseId={courseId}
                onCancel={() => setFormMode(null)}
                onSaved={() => {
                  setFormMode(null);
                  load();
                }}
              />
            )}

            {reviews.length === 0 && formMode !== 'new' && (
              <p className="no-reviews">No reviews yet — be the first!</p>
            )}

            <div className="review-list">
              {reviews.map((review) => {
                const isMine = currentUser && (review.userId?._id ?? review.userId) === currentUser.id;
                const isEditing = formMode && formMode !== 'new' && formMode._id === review._id;
                if (isEditing) {
                  return (
                    <ReviewForm
                      key={review._id}
                      courseId={courseId}
                      existing={review}
                      onCancel={() => setFormMode(null)}
                      onSaved={() => {
                        setFormMode(null);
                        load();
                      }}
                    />
                  );
                }
                return (
                  <div key={review._id} className="review-card">
                    <div className="review-card-top">
                      <span className="review-author">
                        {review.userId?.username || (isMine ? 'You' : 'Anonymous')}
                      </span>
                      {isMine && (
                        <div className="review-card-actions">
                          <button type="button" onClick={() => setFormMode(review)} aria-label="Edit review">
                            Edit
                          </button>
                          <button type="button" onClick={() => handleDelete(review)} aria-label="Delete review">
                            Delete
                          </button>
                        </div>
                      )}
                    </div>
                    <p className="review-card-meta">
                      Quality: {review.quality}/5 &nbsp;•&nbsp; Difficulty: {review.difficulty}/5
                      {review.instructor ? ` • ${review.instructor}` : ''}
                      {review.term ? ` • ${review.term}` : ''}
                      {review.grade ? ` • Grade: ${review.grade}` : ''}
                    </p>
                    {review.comment && <p className="review-card-comment">{review.comment}</p>}
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default CourseDetailPage;
