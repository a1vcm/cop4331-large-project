import { useEffect, useMemo, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import { getCourses } from '../api/courses.js';
import { getErrorMessage } from '../api/client.js';
import './CourseSearchPage.css';

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

function CourseSearchPage({ onBack, onInfoClick, onHelpClick, onAccountClick, onShowReviews, initialQuery = '' }) {
  const [query, setQuery] = useState(initialQuery);
  const [filterBy, setFilterBy] = useState('all');
  const [sortBy, setSortBy] = useState('relevance');
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const loadCourses = async (q) => {
    setLoading(true);
    setError(null);
    try {
      const data = await getCourses(q);
      setCourses(data);
    } catch (err) {
      setError(getErrorMessage(err, 'Failed to load courses.'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- initial data fetch on mount
    loadCourses(initialQuery);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const visibleCourses = useMemo(() => {
    let result = courses;

    if (filterBy !== 'all') {
      result = result.filter((course) => getDifficultyKey(course) === filterBy);
    }

    if (sortBy !== 'relevance') {
      result = [...result].sort((a, b) => {
        switch (sortBy) {
          case 'name':
            return (a.title ?? '').localeCompare(b.title ?? '');
          case 'credits':
            return (a.credits ?? 0) - (b.credits ?? 0);
          case 'difficulty': {
            // Unrated courses sink to the bottom
            const aVal = a.numRatings ? a.avgDifficulty : Infinity;
            const bVal = b.numRatings ? b.avgDifficulty : Infinity;
            return aVal - bVal;
          }
          default:
            return 0;
        }
      });
    }

    return result;
  }, [courses, filterBy, sortBy]);

  const handleSearch = (e) => {
    e.preventDefault();
    loadCourses(query);
  };

  const handleShowReviews = (course) => {
    if (onShowReviews) onShowReviews(course);
  };

  return (
    <div className="course-search-page">
      <TopBar
        showBackButton
        onBack={onBack}
        showCoursesIcon={false}
        onInfoClick={onInfoClick}
        onHelpClick={onHelpClick}
        onAccountClick={onAccountClick}
        fixed
      />
      <div className="course-search-top-spacer" />

      <div className="course-search-content">
        <form className="course-search-bar" onSubmit={handleSearch}>
          <input
            type="text"
            placeholder="Search for a class..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          <button type="submit" aria-label="Search">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="11" cy="11" r="7" />
              <line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
          </button>
        </form>

        <div className="course-search-controls">
          <label className="control-dropdown">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M4 6h16M7 12h10M10 18h4" />
            </svg>
            <select value={filterBy} onChange={(e) => setFilterBy(e.target.value)}>
              <option value="all">Filter By</option>
              <option value="easy">Difficulty: Easy</option>
              <option value="medium">Difficulty: Medium</option>
              <option value="hard">Difficulty: Hard</option>
            </select>
          </label>

          <label className="control-dropdown">
            <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
              <option value="relevance">Sort By</option>
              <option value="name">Name</option>
              <option value="credits">Credits</option>
              <option value="difficulty">Difficulty</option>
            </select>
          </label>
        </div>

        {loading && <p className="results-count">Loading courses...</p>}
        {error && <p className="results-count">{error}</p>}
        {!loading && !error && <p className="results-count">{visibleCourses.length} results</p>}

        <div className="class-list">
          {!loading && !error && visibleCourses.map((course) => {
            const diffKey = getDifficultyKey(course);
            const diff = DIFFICULTY[diffKey];
            return (
              <div key={course._id} className="class-card">
                <div className="class-info">
                  <h3 className="class-name">{course.title}</h3>
                  <p className="class-meta">
                    {course.credits ?? '—'} credits &nbsp;•&nbsp; {course.course_code}
                    {course.department ? ` • ${course.department}` : ''}
                  </p>
                </div>

                <div className="class-actions">
                  <span
                    className="difficulty-badge"
                    style={{ backgroundColor: diff.color }}
                  >
                    {diff.label}
                  </span>
                  <button
                    className="reviews-btn"
                    onClick={() => handleShowReviews(course)}
                  >
                    Show Reviews
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

export default CourseSearchPage;