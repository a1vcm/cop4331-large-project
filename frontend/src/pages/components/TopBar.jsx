import './TopBar.css';
import ThemeToggle from './ThemeToggle';

function TopBar({
  showBackButton = false,
  onBack,
  showInfoIcon = true,
  onInfoClick,
  showHelpIcon = true,
  onHelpClick,
  showCoursesIcon = true,
  onCoursesClick,
  showBookmarksIcon = true,
  onBookmarksClick,
  showAccountIcon = true,
  onAccountClick,
  showThemeToggle = true,
  fixed = false,
  transparent = false,
}) {
  const classNames = [
    'top-bar',
    fixed ? 'top-bar-fixed' : '',
    transparent ? 'top-bar-transparent' : '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <header className={classNames}>
      <div className="top-bar-left">
        {showBackButton && (
          <button aria-label="Back" className="back-btn" onClick={onBack}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M15 18l-6-6 6-6" />
            </svg>
          </button>
        )}
        <span className="top-bar-brand">KnightRate</span>
      </div>

      <nav className="top-bar-icons">
        {showThemeToggle && <ThemeToggle />}

        {showInfoIcon && (
          <button aria-label="Info" className="icon-btn" onClick={onInfoClick}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="12" r="9" />
              <line x1="12" y1="11" x2="12" y2="16" />
              <circle cx="12" cy="8" r="0.5" fill="currentColor" />
            </svg>
          </button>
        )}
        {showHelpIcon && (
          <button aria-label="Help" className="icon-btn" onClick={onHelpClick}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="12" r="9" />
              <path d="M9.5 9a2.5 2.5 0 0 1 5 0c0 1.5-2.5 2-2.5 3.5" />
              <circle cx="12" cy="16.5" r="0.5" fill="currentColor" />
            </svg>
          </button>
        )}
        {showCoursesIcon && (
          <button aria-label="Courses" className="icon-btn" onClick={onCoursesClick}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M2 9l10-5 10 5-10 5-10-5z" />
              <path d="M6 11v5c0 1.5 2.5 3 6 3s6-1.5 6-3v-5" />
            </svg>
          </button>
        )}
        {showBookmarksIcon && (
          <button aria-label="Bookmarks" className="icon-btn" onClick={onBookmarksClick}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M6 3h12a1 1 0 0 1 1 1v17l-7-4-7 4V4a1 1 0 0 1 1-1z" />
            </svg>
          </button>
        )}
        {showAccountIcon && (
          <button aria-label="Account" className="icon-btn" onClick={onAccountClick}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="8" r="4" />
              <path d="M4 20c0-4 4-6 8-6s8 2 8 6" />
            </svg>
          </button>
        )}
      </nav>
    </header>
  );
}

export default TopBar;