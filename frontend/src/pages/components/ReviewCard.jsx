import Stars from './Stars.jsx';
import './ReviewCard.css';

// RateMyProfessor-style review card: author + comment on the left, tag
// pills + a bookmark toggle stacked on the right (courseLabel/onCourseClick
// are only passed on the cross-course Bookmarks page, to identify which
// course each bookmarked review belongs to).
function ReviewCard({
  review,
  isMine,
  isBookmarked,
  isLoggedIn,
  onToggleBookmark,
  onEdit,
  onDelete,
  courseLabel,
  onCourseClick,
}) {
  return (
    <div className="review-card">
      {courseLabel && (
        <button type="button" className="review-card-course-link" onClick={onCourseClick}>
          {courseLabel}
        </button>
      )}

      <div className="review-card-row">
        <div className="review-card-main">
          <div className="review-card-top">
            <span className="review-author">
              Review by: {review.userId?.username || (isMine ? 'You' : 'Anonymous')}
            </span>
            <Stars value={review.quality} readOnly allowHalf size={14} />
            {isMine && (
              <div className="review-card-owner-actions">
                <button type="button" onClick={onEdit} aria-label="Edit review">
                  Edit
                </button>
                <button type="button" onClick={onDelete} aria-label="Delete review">
                  Delete
                </button>
              </div>
            )}
          </div>

          {review.comment && <p className="review-card-comment">{review.comment}</p>}

          <p className="review-card-meta">
            Difficulty: {review.difficulty}/5
            {review.workload ? ` • Workload: ${review.workload}/5` : ''}
            {review.gradingFairness ? ` • Grading Fairness: ${review.gradingFairness}/5` : ''}
            {review.professorRating ? ` • Professor: ${review.professorRating}/5` : ''}
            {review.instructor ? ` • ${review.instructor}` : ''}
            {review.term ? ` • ${review.term}` : ''}
            {review.grade ? ` • Grade: ${review.grade}` : ''}
          </p>
        </div>

        <div className="review-card-side">
          {review.tags?.length > 0 && (
            <div className="review-card-tags">
              {review.tags.map((tag) => (
                <span key={tag} className="review-tag">
                  {tag}
                </span>
              ))}
            </div>
          )}
          {isLoggedIn && (
            <button
              type="button"
              onClick={onToggleBookmark}
              aria-label={isBookmarked ? 'Remove bookmark' : 'Bookmark review'}
              aria-pressed={isBookmarked}
              className={`review-bookmark-btn ${isBookmarked ? 'bookmarked' : ''}`}
            >
              <svg viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" fill={isBookmarked ? 'currentColor' : 'none'}>
                <path d="M6 3h12a1 1 0 0 1 1 1v17l-7-4-7 4V4a1 1 0 0 1 1-1z" />
              </svg>
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

export default ReviewCard;
