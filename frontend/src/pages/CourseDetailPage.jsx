import { useEffect, useMemo, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import ReviewCard from './components/ReviewCard.jsx';
import { getCourseById } from '../api/courses.js';
import { getCourseReviews, deleteReview } from '../api/reviews.js';
import { getMyBookmarks, createBookmark, deleteBookmark } from '../api/bookmarks.js';
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

const PAGE_SIZE = 5;

function CourseDetailPage({
  courseId,
  onBack,
  onAccountClick,
  onInfoClick,
  onHelpClick,
  onCoursesClick,
  onWriteReview,
  onViewResources,
  refreshSignal,
}) {
  const [course, setCourse] = useState(null);
  const [reviews, setReviews] = useState([]);
  const [bookmarkedIds, setBookmarkedIds] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(0);

  const currentUser = getAuthUser();

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      // Bookmarks are secondary — an expired/invalid token shouldn't take
      // down the whole page, just leave bookmark state empty.
      const [courseData, reviewData, bookmarkData] = await Promise.all([
        getCourseById(courseId),
        getCourseReviews(courseId),
        isLoggedIn() ? getMyBookmarks().catch(() => []) : Promise.resolve([]),
      ]);
      setCourse(courseData);
      setReviews(reviewData);
      setBookmarkedIds(bookmarkData);
    } catch (err) {
      setError(getErrorMessage(err, 'Failed to load this course.'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- initial data fetch on mount
    setPage(0);
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId, refreshSignal]);

  const myReview = currentUser
    ? reviews.find((r) => (r.userId?._id ?? r.userId) === currentUser.id)
    : null;

  const toggleBookmark = async (review) => {
    const isBookmarked = bookmarkedIds.includes(review._id);
    try {
      if (isBookmarked) {
        await deleteBookmark(review._id);
        setBookmarkedIds((prev) => prev.filter((id) => id !== review._id));
      } else {
        await createBookmark(review._id);
        setBookmarkedIds((prev) => [...prev, review._id]);
      }
    } catch (err) {
      setError(getErrorMessage(err, 'Failed to update bookmark.'));
    }
  };

  const handleDelete = async (review) => {
    if (!window.confirm("Delete this review? This can't be undone.")) return;
    try {
      await deleteReview(review._id);
      load();
    } catch (err) {
      setError(getErrorMessage(err, 'Failed to delete review.'));
    }
  };

  // Star distribution, bucketed by rounded quality (1-5) — computed
  // client-side from the already-fully-fetched reviews array.
  const distribution = useMemo(() => {
    const counts = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    reviews.forEach((r) => {
      const bucket = Math.min(5, Math.max(1, Math.round(r.quality)));
      counts[bucket] += 1;
    });
    const max = Math.max(1, ...Object.values(counts));
    return { counts, max };
  }, [reviews]);

  const totalPages = Math.max(1, Math.ceil(reviews.length / PAGE_SIZE));
  const pagedReviews = reviews.slice(page * PAGE_SIZE, page * PAGE_SIZE + PAGE_SIZE);

  const diffKey = course ? getDifficultyKey(course) : 'unrated';
  const diff = DIFFICULTY[diffKey];

  return (
    <div className="course-detail-page">
      <TopBar
        showBackButton
        onBack={onBack}
        showCoursesIcon={false}
        onInfoClick={onInfoClick}
        onHelpClick={onHelpClick}
        onCoursesClick={onCoursesClick}
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

              <div className="course-rating-summary">
                <div className="course-rating-left">
                  <div className="course-rating-big">
                    <span className="course-rating-number">
                      {course.numRatings === 0 ? '—' : course.avgRating.toFixed(1)}
                    </span>
                    <span className="course-rating-outof">/ 5.0</span>
                  </div>
                  <span className="course-rating-count">
                    {course.numRatings} {course.numRatings === 1 ? 'review' : 'reviews'}
                  </span>
                  <span className="difficulty-badge" style={{ backgroundColor: diff.color }}>
                    {diff.label} difficulty
                  </span>

                  {!isLoggedIn() ? (
                    <button type="button" className="review-link-btn primary" onClick={onAccountClick}>
                      Log in to review
                    </button>
                  ) : (
                    !myReview && (
                      <button
                        type="button"
                        className="review-link-btn primary"
                        onClick={() => onWriteReview(courseId)}
                      >
                        Write a Review
                      </button>
                    )
                  )}

                  {onViewResources && (
                    <button
                      type="button"
                      className="review-link-btn course-resources-btn"
                      onClick={() => onViewResources(courseId)}
                    >
                      Course Resources
                    </button>
                  )}
                </div>

                <div className="course-rating-right">
                  {[5, 4, 3, 2, 1].map((star) => (
                    <div className="distribution-row" key={star}>
                      <span className="distribution-star-label">{star}★</span>
                      <div className="distribution-bar-track">
                        <div
                          className="distribution-bar-fill"
                          style={{ width: `${(distribution.counts[star] / distribution.max) * 100}%` }}
                        />
                      </div>
                      <span className="distribution-count">{distribution.counts[star]}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            <div className="reviews-header-row">
              <h2 className="reviews-heading">Reviews ({reviews.length})</h2>
            </div>

            {reviews.length === 0 && <p className="no-reviews">No reviews yet — be the first!</p>}

            <div className="review-list">
              {pagedReviews.map((review) => {
                const isMine = currentUser && (review.userId?._id ?? review.userId) === currentUser.id;
                return (
                  <ReviewCard
                    key={review._id}
                    review={review}
                    isMine={isMine}
                    isBookmarked={bookmarkedIds.includes(review._id)}
                    isLoggedIn={isLoggedIn()}
                    onToggleBookmark={() => toggleBookmark(review)}
                    onEdit={() => onWriteReview(courseId, review)}
                    onDelete={() => handleDelete(review)}
                  />
                );
              })}
            </div>

            {totalPages > 1 && (
              <div className="review-pagination">
                <button
                  type="button"
                  onClick={() => setPage((p) => Math.max(0, p - 1))}
                  disabled={page === 0}
                  aria-label="Previous page"
                >
                  ← Prev
                </button>
                <span className="review-pagination-status">
                  Page {page + 1} of {totalPages}
                </span>
                <button
                  type="button"
                  onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                  disabled={page >= totalPages - 1}
                  aria-label="Next page"
                >
                  Next →
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

export default CourseDetailPage;
