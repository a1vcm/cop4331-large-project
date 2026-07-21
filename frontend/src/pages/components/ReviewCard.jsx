import Stars from './Stars.jsx';
import './ReviewCard.css';

// RateMyProfessor-style review card: author + star rating, bookmark toggle,
// edit/delete for the review's own author, tags/badges the reviewer picked.
function ReviewCard({ review, isMine, isBookmarked, isLoggedIn, onToggleBookmark, onEdit, onDelete }) {
  return (
    <div className="review-card">
      <div className="review-card-top">
        <div className="review-card-identity">
          <span className="review-author">{review.userId?.username || (isMine ? 'You' : 'Anonymous')}</span>
          <Stars value={review.quality} readOnly allowHalf size={14} />
        </div>
        <div className="review-card-actions">
          {isLoggedIn && (
            <button
              type="button"
              onClick={onToggleBookmark}
              aria-label={isBookmarked ? 'Remove bookmark' : 'Bookmark review'}
              className={isBookmarked ? 'bookmarked' : ''}
            >
              {isBookmarked ? 'Bookmarked' : 'Bookmark'}
            </button>
          )}
          {isMine && (
            <>
              <button type="button" onClick={onEdit} aria-label="Edit review">
                Edit
              </button>
              <button type="button" onClick={onDelete} aria-label="Delete review">
                Delete
              </button>
            </>
          )}
        </div>
      </div>

      <p className="review-card-meta">
        Difficulty: {review.difficulty}/5
        {review.professorRating ? ` • Professor: ${review.professorRating}/5` : ''}
        {review.attendance ? ` • Attendance: ${review.attendance}/5` : ''}
        {review.instructor ? ` • ${review.instructor}` : ''}
        {review.term ? ` • ${review.term}` : ''}
        {review.grade ? ` • Grade: ${review.grade}` : ''}
      </p>

      {review.comment && <p className="review-card-comment">{review.comment}</p>}

      {review.tags?.length > 0 && (
        <div className="review-card-tags">
          {review.tags.map((tag) => (
            <span key={tag} className="review-tag">
              {tag}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}

export default ReviewCard;
