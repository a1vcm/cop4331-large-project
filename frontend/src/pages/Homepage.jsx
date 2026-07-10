import { useState } from 'react';
import TopBar from './components/TopBar.jsx';
import ucfLogo from '../assets/ICON_UCF.png';
import stockUcf from '../assets/STOCK_UCF.jpg';
import './Homepage.css';

function Homepage({
  showBackButton = false,
  onBack,
  onAccountClick,
  onInfoClick,
  onHelpClick,
  onCoursesClick,
}) {
  const [query, setQuery] = useState('');
  const [isExpanded, setIsExpanded] = useState(false);

  const handleSearch = (e) => {
    e.preventDefault();
    console.log('Searching for:', query);
  };

  const toggleExpanded = () => {
    setIsExpanded((prev) => !prev);
  };

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

      {/* Hero — fills the first screen */}
      <section
        className={`hero ${isExpanded ? 'expanded-state' : ''}`}
        style={{ backgroundImage: `url(${stockUcf})` }}
      >
        <div className="hero-overlay">
          <h1 className="hero-title">Welcome to KnightRate!</h1>

          <form className="search-bar" onSubmit={handleSearch}>
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
        </div>
      </section>

      {/* Expandable panel — slides up over the hero. Handle/arrow always sits at its top edge, so it can be clicked to expand OR collapse. */}
      <div className={`expandable-panel ${isExpanded ? 'expanded' : ''}`}>
        <button
          className="pull-handle"
          aria-label={isExpanded ? 'Collapse' : 'Show more'}
          onClick={toggleExpanded}
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M5 15l7-7 7 7" />
          </svg>
        </button>

        <div className="panel-content">
          <section className="intro">
            <img src={ucfLogo} alt="UCF Logo" className="intro-logo" />
            <div className="intro-text">
              <span className="line intro-heading" />
              <span className="line intro-line" />
              <span className="line intro-line" />
              <span className="line intro-line short" />
            </div>
          </section>

          <h2 className="popular-classes-heading">Popular Classes</h2>

          <section className="cards-row">
            <div className="card" />
            <div className="card" />
            <div className="card" />
            <div className="card" />
          </section>
        </div>
      </div>
    </div>
  );
}

export default Homepage;