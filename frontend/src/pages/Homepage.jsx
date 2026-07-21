import { useEffect, useState } from 'react';
import TopBar from './components/TopBar.jsx';
import Footer from './components/Footer.jsx';
import CourseSearchBar from './components/CourseSearchBar.jsx';
import ucfLogo from '../assets/ucflogos.png';
import ucfWordmark from '../assets/logo.png';
import campusPhoto from '../assets/ucfcampus.png';
import { getCourses } from '../api/courses.js';
import './Homepage.css';

function Homepage({
  showBackButton = false,
  onBack,
  onAccountClick,
  onInfoClick,
  onCoursesClick,
  onSearch,
  onCourseClick,
}) {
  const [query, setQuery] = useState('');
  const [popularCourses, setPopularCourses] = useState([]);

  useEffect(() => {
    getCourses(undefined, { sort: 'recent' })
      .then((courses) => setPopularCourses(courses.slice(0, 4)))
      .catch(() => setPopularCourses([]));
  }, []);

  const handleSearch = (e) => {
    e.preventDefault();
    if (onSearch) onSearch(query);
  };

  const scrollToHowItWorks = () => {
    document.getElementById('how-it-works')?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <div className="homepage">
      <TopBar
        showBackButton={showBackButton}
        onBack={onBack}
        onAccountClick={onAccountClick}
        onInfoClick={onInfoClick}
        showHelpIcon={false}
        onCoursesClick={onCoursesClick}
        fixed
        transparent
      />

      {/* <main> landmark for screen readers / Lighthouse; wraps everything
          below the (fixed) top bar. */}
      <main>
        {/* Hero — a normal-flow banner, not a fixed 100vh panel. The page
            simply scrolls from here into the sections below. */}
        <section className="hero" style={{ backgroundImage: `url(${campusPhoto})` }}>
          <div className="hero-overlay">
            <img src={ucfWordmark} alt="UCF" className="hero-wordmark" />
            <h1 className="hero-title">KnightRate</h1>
            <p className="hero-tagline">
              Real ratings from real students, all in one place. Browse honest reviews on classes
              and gauge valuable resources before you commit.
            </p>

            <CourseSearchBar
              value={query}
              onChange={setQuery}
              onSubmit={handleSearch}
              onSelectCourse={(course) => (onCourseClick ? onCourseClick(course) : onCoursesClick?.())}
              placeholder="Search classes..."
            />

            <div className="hero-links">
              <button type="button" className="hero-link" onClick={() => onCoursesClick?.()}>
                Browse Categories
              </button>
              <span className="hero-link-divider" aria-hidden="true" />
              <button type="button" className="hero-link" onClick={scrollToHowItWorks}>
                How It Works
              </button>
            </div>
          </div>
        </section>

        <div className="homepage-content">
          <section className="intro" id="how-it-works">
            <img src={ucfLogo} alt="UCF Logo" className="intro-logo" />
            <div className="intro-text">
              <h2 className="intro-heading">Made for Knights, by Knights</h2>
              <p className="intro-line">
                KnightRate started as a student project to help our own campus community make
                better decisions. Every review, rating, and recommendation comes from someone
                who&apos;s actually been there.
              </p>
            </div>
          </section>

          <h2 className="popular-classes-heading">Trending Classes This Week</h2>

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
        </div>

        <Footer />
      </main>
    </div>
  );
}

export default Homepage;
