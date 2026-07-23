import { useEffect, useMemo, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import CourseSearchBar from './components/CourseSearchBar.jsx';
import { getCourses } from '../api/courses.js';
import { getErrorMessage } from '../api/client.js';
import './CourseSearchPage.css';

const DIFFICULTY = {
  easy: { label: 'Easy', className: 'difficulty-easy' },
  medium: { label: 'Moderate', className: 'difficulty-medium' },
  hard: { label: 'Hard', className: 'difficulty-hard' },
  unrated: { label: 'Not yet rated', className: 'difficulty-unrated' },
};

const PAGE_SIZE_OPTIONS = [10, 5, 25, 50, 'all'];

function getDifficultyKey(course) {
  if (!course.numRatings) return 'unrated';
  if (course.avgDifficulty <= 2) return 'easy';
  if (course.avgDifficulty <= 3.5) return 'medium';
  return 'hard';
}

function CourseSearchPage({
  onBack,
  onInfoClick,
  onHelpClick,
  onBookmarksClick,
  onAccountClick,
  onShowReviews,
  onLogoClick,
  initialQuery = '',
}) {
  const [query, setQuery] = useState(initialQuery);
  const [filterBy, setFilterBy] = useState('all');
  const [prefixFilter, setPrefixFilter] = useState('all');
  const [sortBy, setSortBy] = useState('relevance');
  const [pageSize, setPageSize] = useState(10);
  const [visibleCount, setVisibleCount] = useState(10);
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

  const prefixes = useMemo(() => {
    const set = new Set(courses.map((course) => course.department).filter(Boolean));
    return [...set].sort();
  }, [courses]);

  const visibleCourses = useMemo(() => {
    let result = courses;

    if (prefixFilter !== 'all') {
      result = result.filter((course) => course.department === prefixFilter);
    }

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
  }, [courses, prefixFilter, filterBy, sortBy]);

  const displayedCourses = useMemo(() => {
    if (pageSize === 'all') return visibleCourses;
    return visibleCourses.slice(0, visibleCount);
  }, [visibleCourses, visibleCount, pageSize]);

  const resetVisibleCount = (size = pageSize) => {
    setVisibleCount(size);
  };

  const handleFilterByChange = (value) => {
    setFilterBy(value);
    resetVisibleCount();
  };

  const handlePrefixFilterChange = (value) => {
    setPrefixFilter(value);
    resetVisibleCount();
  };

  const handleSortByChange = (value) => {
    setSortBy(value);
    resetVisibleCount();
  };

  const handlePageSizeChange = (value) => {
    const size = value === 'all' ? 'all' : Number(value);
    setPageSize(size);
    resetVisibleCount(size);
  };

  const handleShowMore = () => {
    if (pageSize === 'all') return;
    setVisibleCount((count) => count + pageSize);
  };

  const handleSearch = (e) => {
    e.preventDefault();
    resetVisibleCount();
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
        onLogoClick={onLogoClick}
        showCoursesIcon={false}
        onInfoClick={onInfoClick}
        onHelpClick={onHelpClick}
        onBookmarksClick={onBookmarksClick}
        onAccountClick={onAccountClick}
        fixed
      />
      <div className="course-search-top-spacer" />

      <div className="course-search-content">
        <CourseSearchBar
          value={query}
          onChange={setQuery}
          onSubmit={handleSearch}
          onSelectCourse={handleShowReviews}
          formClassName="course-search-bar"
        />

        <div className="course-search-controls">
          <div className="course-search-controls-left">
            <label className="control-dropdown">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M4 6h16M7 12h10M10 18h4" />
              </svg>
              <select value={filterBy} onChange={(e) => handleFilterByChange(e.target.value)}>
                <option value="all">Filter By</option>
                <option value="easy">Difficulty: Easy</option>
                <option value="medium">Difficulty: Moderate</option>
                <option value="hard">Difficulty: Hard</option>
              </select>
            </label>

            <label className="control-dropdown">
              <select value={prefixFilter} onChange={(e) => handlePrefixFilterChange(e.target.value)}>
                <option value="all">All Prefixes</option>
                {prefixes.map((prefix) => (
                  <option key={prefix} value={prefix}>
                    {prefix}
                  </option>
                ))}
              </select>
            </label>

            <label className="control-dropdown">
              <select value={sortBy} onChange={(e) => handleSortByChange(e.target.value)}>
                <option value="relevance">Sort By</option>
                <option value="name">Name</option>
                <option value="credits">Credits</option>
                <option value="difficulty">Difficulty</option>
              </select>
            </label>
          </div>

          <label className="control-dropdown control-dropdown-pagesize">
            <select
              value={pageSize}
              onChange={(e) => handlePageSizeChange(e.target.value)}
            >
              {PAGE_SIZE_OPTIONS.map((size) => (
                <option key={size} value={size}>
                  Show {size === 'all' ? 'All' : size}
                </option>
              ))}
            </select>
          </label>
        </div>

        {loading && <p className="results-count">Loading courses...</p>}
        {error && <p className="results-count">{error}</p>}
        {!loading && !error && (
          <p className="results-count">
            {visibleCourses.length} result{visibleCourses.length === 1 ? '' : 's'}
            {displayedCourses.length < visibleCourses.length ? ` — showing ${displayedCourses.length}` : ''}
          </p>
        )}

        <div className="class-list">
          {!loading && !error && displayedCourses.map((course) => {
            const diffKey = getDifficultyKey(course);
            const diff = DIFFICULTY[diffKey];
            return (
              <div key={course._id} className="class-card">
                <div className="class-info">
                  <h3 className="class-name">
                    {course.course_code} - {course.title}
                  </h3>
                  <p className="class-meta">
                    {course.credits ?? '—'} credits &nbsp;·&nbsp; {course.department ?? '—'}
                  </p>
                </div>

                <div className="class-actions">
                  <span className={`difficulty-badge ${diff.className}`}>{diff.label}</span>
                  <button
                    className="reviews-btn"
                    onClick={() => handleShowReviews(course)}
                  >
                    View
                  </button>
                </div>
              </div>
            );
          })}
        </div>

        {!loading && !error && displayedCourses.length < visibleCourses.length && (
          <button className="show-more-btn" onClick={handleShowMore}>
            Next
          </button>
        )}
      </div>
    </div>
  );
}

export default CourseSearchPage;