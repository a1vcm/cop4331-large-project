import { useEffect, useRef, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import Footer from './components/Footer.jsx';
import CourseSearchBar from './components/CourseSearchBar.jsx';
import ucfLogo from '../assets/ICON_UCF.png';
import stockUcf from '../assets/STOCK_UCF.jpg';
import { getCourses } from '../api/courses.js';
import './Homepage.css';

function Homepage({
  showBackButton = false,
  onBack,
  onAccountClick,
  onInfoClick,
  onHelpClick,
  onCoursesClick,
  onSearch,
  onCourseClick,
}) {
  const [query, setQuery] = useState('');
  const [isExpanded, setIsExpanded] = useState(false);
  const [popularCourses, setPopularCourses] = useState([]);
  const touchStartY = useRef(null);

  useEffect(() => {
    getCourses(undefined, { sort: 'recent' })
      .then((courses) => setPopularCourses(courses.slice(0, 4)))
      .catch(() => setPopularCourses([]));
  }, []);

  const handleSearch = (e) => {
    e.preventDefault();
    if (onSearch) onSearch(query);
  };

  const toggleExpanded = () => {
    setIsExpanded((prev) => !prev);
  };

  // Swipe up on the hero to expand, swipe down on the handle to collapse.
  // Click still works too — this is additive, not a replacement.
  const SWIPE_THRESHOLD_PX = 40;

  const handleTouchStart = (e) => {
    touchStartY.current = e.touches[0].clientY;
  };

  const makeTouchEndHandler = (direction, action) => (e) => {
    if (touchStartY.current === null) return;
    const deltaY = e.changedTouches[0].clientY - touchStartY.current;
    touchStartY.current = null;
    const swiped = direction === 'up' ? deltaY < -SWIPE_THRESHOLD_PX : deltaY > SWIPE_THRESHOLD_PX;
    if (swiped) action();
  };

  const handleHeroTouchEnd = makeTouchEndHandler('up', () => setIsExpanded(true));
  const handlePanelTouchEnd = makeTouchEndHandler('down', () => setIsExpanded(false));

  return (
    <div className="homepage">
      <TopBar
        showBackButton={showBackButton}
        onBack={onBack}
        onAccountClick={onAccountClick}
        onInfoClick={onInfoClick}
        onHelpClick={onHelpClick}
        onCoursesClick={onCoursesClick}
        fixed
        transparent
      />

      {/* <main> landmark for screen readers / Lighthouse; wraps everything
          below the (fixed) top bar. */}
      <main>
        {/* Hero — fills the first screen */}
        <section
          className={`hero ${isExpanded ? 'expanded-state' : ''}`}
          style={{ backgroundImage: `url(${stockUcf})` }}
          onTouchStart={handleTouchStart}
          onTouchEnd={handleHeroTouchEnd}
        >
          <div className="hero-overlay">
            <h1 className="hero-title">Welcome to KnightRate!</h1>
            <p className="hero-tagline">Real course ratings from UCF students, for UCF students.</p>

            <CourseSearchBar
              value={query}
              onChange={setQuery}
              onSubmit={handleSearch}
              onSelectCourse={(course) => (onCourseClick ? onCourseClick(course) : onCoursesClick?.())}
            />
          </div>
        </section>

        {/* Expandable panel — slides up over the hero. Handle/arrow always sits at its top edge, so it can be clicked to expand OR collapse. */}
        <div className={`expandable-panel ${isExpanded ? 'expanded' : ''}`}>
          <button
            className="pull-handle"
            aria-label={isExpanded ? 'Collapse' : 'Show more'}
            aria-expanded={isExpanded}
            onClick={toggleExpanded}
            onTouchStart={handleTouchStart}
            onTouchEnd={handlePanelTouchEnd}
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M5 15l7-7 7 7" />
            </svg>
          </button>

          <div className="panel-content">
            <section className="intro">
              <img src={ucfLogo} alt="UCF Logo" className="intro-logo" />
              <div className="intro-text">
                <h2 className="intro-heading">Find the right class, from students who've taken it</h2>
                <p className="intro-line">
                  KnightRate is a course review platform built for UCF Computer Science and IT
                  students — search the catalog, read real ratings for difficulty and quality, and
                  share your own experience once you've taken a class.
                </p>
              </div>
            </section>

            <h2 className="popular-classes-heading">Recently Reviewed</h2>

            <section className="cards-row">
              {popularCourses.length === 0 ? (
                <p className="cards-row-empty">Loading classes…</p>
              ) : (
                popularCourses.map((course) => (
                  <button
                    key={course._id}
                    type="button"
                    className="card"
                    onClick={() => (onCourseClick ? onCourseClick(course) : onCoursesClick?.())}
                  >
                    <span className="card-code">{course.course_code}</span>
                    <span className="card-title">{course.title}</span>
                  </button>
                ))
              )}
            </section>

            <Footer />
          </div>
        </div>
      </main>
    </div>
  );
}

export default Homepage;
