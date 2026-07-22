import { useEffect, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import ReviewCard from './components/ReviewCard.jsx';
import { getMyBookmarks, deleteBookmark } from '../api/bookmarks.js';
import { getErrorMessage } from '../api/client.js';
import './BookmarksPage.css';

function BookmarksPage({ onBack, onInfoClick, onHelpClick, onCoursesClick, onAccountClick, onCourseClick }) {
  const [bookmarks, setBookmarks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const load = () => {
    setLoading(true);
    setError(null);
    getMyBookmarks()
      .then(setBookmarks)
      .catch((err) => setError(getErrorMessage(err, 'Failed to load your bookmarks.')))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- initial data fetch on mount
    load();
  }, []);

  const handleRemove = async (review) => {
    try {
      await deleteBookmark(review._id);
      setBookmarks((prev) => prev.filter((b) => b?.reviewId?._id !== review._id));
    } catch (err) {
      setError(getErrorMessage(err, 'Failed to remove bookmark.'));
    }
  };

  return (
    <div className="bookmarks-page">
      <TopBar
        showBackButton
        onBack={onBack}
        showBookmarksIcon={false}
        onInfoClick={onInfoClick}
        onHelpClick={onHelpClick}
        onCoursesClick={onCoursesClick}
        onAccountClick={onAccountClick}
        fixed
      />
      <div className="bookmarks-top-spacer" />

      <div className="bookmarks-content">
        <h1 className="bookmarks-heading">Your Bookmarks</h1>

        {loading && <p className="bookmarks-status">Loading your bookmarks…</p>}
        {error && <p className="bookmarks-status">{error}</p>}
        {!loading && !error && bookmarks.length === 0 && (
          <p className="bookmarks-status">
            You haven't bookmarked any reviews yet — tap the bookmark icon on a review to save it here.
          </p>
        )}

        <div className="bookmarks-list">
          {!loading &&
            !error &&
            bookmarks.map((bookmark) => {
              // The backend may still be running the older version of this
              // endpoint (deploys only happen on merge to main), which
              // returns bare reviewIds instead of populated bookmark docs —
              // skip anything that isn't in the shape we can render rather
              // than crashing on it.
              const review = bookmark && typeof bookmark === 'object' ? bookmark.reviewId : null;
              if (!review || typeof review !== 'object') return null;

              const course = typeof review.courseId === 'object' ? review.courseId : null;
              return (
                <ReviewCard
                  key={bookmark._id ?? review._id}
                  review={review}
                  isMine={false}
                  isBookmarked
                  isLoggedIn
                  onToggleBookmark={() => handleRemove(review)}
                  courseLabel={course ? `${course.course_code} - ${course.title}` : 'View course'}
                  onCourseClick={() => course && onCourseClick && onCourseClick(course)}
                />
              );
            })}
        </div>

        {!loading && !error && bookmarks.length > 0 && bookmarks.every((b) => !b || typeof b.reviewId !== 'object') && (
          <p className="bookmarks-status">
            Your bookmarks are saved, but this environment's backend hasn't picked up the update that
            shows their full details yet — check back after the next deploy.
          </p>
        )}
      </div>
    </div>
  );
}

export default BookmarksPage;
