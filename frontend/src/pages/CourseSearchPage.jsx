import { useState } from 'react';
import TopBar from './components/TopBar.jsx';
import './CourseSearchPage.css';

const DIFFICULTY = {
  easy: { label: 'Easy', color: '#7FCB8F' },
  medium: { label: 'Medium', color: '#F2D14A' },
  hard: { label: 'Hard', color: '#E57373' },
};

const CLASSES = [
  {
    id: 1,
    name: 'Introduction to Programming',
    credits: 3,
    subject: 'COP',
    number: '3502',
    difficulty: 'easy',
  },
  {
    id: 2,
    name: 'Data Structures and Algorithms',
    credits: 3,
    subject: 'COP',
    number: '3530',
    difficulty: 'easy',
  },
  {
    id: 3,
    name: 'Discrete Structures',
    credits: 3,
    subject: 'COT',
    number: '3100',
    difficulty: 'hard',
  },
  {
    id: 4,
    name: 'Computer Organization',
    credits: 3,
    subject: 'CDA',
    number: '3103',
    difficulty: 'medium',
  },
  {
    id: 5,
    name: 'Software Engineering',
    credits: 3,
    subject: 'COP',
    number: '4331',
    difficulty: 'medium',
  },
  {
    id: 6,
    name: 'Operating Systems',
    credits: 3,
    subject: 'COP',
    number: '4600',
    difficulty: 'medium',
  },
];

function CourseSearchPage({ onBack, onInfoClick, onHelpClick, onAccountClick, onShowReviews }) {
  const [query, setQuery] = useState('');
  const [filterBy, setFilterBy] = useState('all');
  const [sortBy, setSortBy] = useState('relevance');

  const handleSearch = (e) => {
    e.preventDefault();
    console.log('Searching for:', query);
  };

  const handleShowReviews = (classItem) => {
    console.log('Show reviews for:', classItem.subject, classItem.number);
    if (onShowReviews) onShowReviews(classItem);
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

        <p className="results-count">{CLASSES.length} results</p>

        <div className="class-list">
          {CLASSES.map((classItem) => {
            const diff = DIFFICULTY[classItem.difficulty];
            return (
              <div key={classItem.id} className="class-card">
                <div className="class-info">
                  <h3 className="class-name">{classItem.name}</h3>
                  <p className="class-meta">
                    {classItem.credits} credits &nbsp;•&nbsp; {classItem.subject} {classItem.number}
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
                    onClick={() => handleShowReviews(classItem)}
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