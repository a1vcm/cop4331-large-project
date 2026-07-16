import { useState, useEffect } from 'react';
 
//Decide the starting theme: a saved choice wins; otherwise follow the OS setting.
function getInitialTheme() {
  const saved = localStorage.getItem('theme');
  if (saved === 'light' || saved === 'dark') return saved;
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}
 
function ThemeToggle() {
  const [theme, setTheme] = useState(getInitialTheme);
 
  // Apply the theme to <html> and remember it whenever it changes.
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);
 
  const toggle = () => setTheme((t) => (t === 'light' ? 'dark' : 'light'));
 
  const isLight = theme === 'light';
 
  return (
    <button
      aria-label={isLight ? 'Switch to dark mode' : 'Switch to light mode'}
      className="icon-btn"
      onClick={toggle}
    >
      {isLight ? (
        // Moon — shown in light mode (click to go dark)
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
        </svg>
      ) : (
        // Sun — shown in dark mode (click to go light)
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="4" />
          <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
        </svg>
      )}
    </button>
  );
}
 
export default ThemeToggle;