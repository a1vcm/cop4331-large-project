import { useEffect, useRef, useState } from 'react';
import { getCourses } from '../../api/courses.js';
import './CourseSearchBar.css';

const DEBOUNCE_MS = 300;
const MAX_SUGGESTIONS = 6;

// Shared debounced-autocomplete search bar used by Homepage and
// CourseSearchPage. The two pages style their own <form> differently
// (formClassName), but share the fetch/debounce/keyboard-nav logic.
function CourseSearchBar({
  value,
  onChange,
  onSubmit,
  onSelectCourse,
  placeholder = 'Search for a class...',
  formClassName = 'search-bar',
}) {
  const [suggestions, setSuggestions] = useState([]);
  const [open, setOpen] = useState(false);
  const [highlightedIndex, setHighlightedIndex] = useState(-1);
  const containerRef = useRef(null);

  useEffect(() => {
    const trimmed = value.trim();
    if (!trimmed) {
      setSuggestions([]);
      setOpen(false);
      return;
    }

    let cancelled = false;
    const timer = setTimeout(() => {
      getCourses(trimmed)
        .then((courses) => {
          if (cancelled) return;
          setSuggestions(courses.slice(0, MAX_SUGGESTIONS));
          setOpen(true);
          setHighlightedIndex(-1);
        })
        .catch(() => {
          if (!cancelled) setSuggestions([]);
        });
    }, DEBOUNCE_MS);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [value]);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (containerRef.current && !containerRef.current.contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const selectCourse = (course) => {
    setOpen(false);
    setSuggestions([]);
    if (onSelectCourse) onSelectCourse(course);
  };

  const handleKeyDown = (e) => {
    if (!open || suggestions.length === 0) return;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setHighlightedIndex((i) => (i + 1) % suggestions.length);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setHighlightedIndex((i) => (i - 1 + suggestions.length) % suggestions.length);
    } else if (e.key === 'Enter' && highlightedIndex >= 0) {
      e.preventDefault();
      selectCourse(suggestions[highlightedIndex]);
    } else if (e.key === 'Escape') {
      setOpen(false);
    }
  };

  const handleSubmit = (e) => {
    setOpen(false);
    if (onSubmit) onSubmit(e);
  };

  return (
    <div className="course-search-bar-wrapper" ref={containerRef}>
      <form className={formClassName} onSubmit={handleSubmit}>
        <input
          type="text"
          placeholder={placeholder}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={handleKeyDown}
          onFocus={() => {
            if (suggestions.length > 0) setOpen(true);
          }}
          role="combobox"
          aria-expanded={open}
          aria-autocomplete="list"
          autoComplete="off"
        />
        <button type="submit" aria-label="Search">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="11" cy="11" r="7" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
        </button>
      </form>

      {open && suggestions.length > 0 && (
        <ul className="search-suggestions" role="listbox">
          {suggestions.map((course, i) => (
            <li
              key={course._id}
              role="option"
              aria-selected={i === highlightedIndex}
              className={`search-suggestion ${i === highlightedIndex ? 'highlighted' : ''}`}
              onMouseDown={(e) => {
                // Fires before the input's blur, so the dropdown-close-on-blur
                // logic doesn't swallow the click before selectCourse runs.
                e.preventDefault();
                selectCourse(course);
              }}
              onMouseEnter={() => setHighlightedIndex(i)}
            >
              <span className="suggestion-code">{course.course_code}</span>
              <span className="suggestion-title">{course.title}</span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default CourseSearchBar;
