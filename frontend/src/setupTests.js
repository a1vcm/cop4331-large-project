import '@testing-library/jest-dom';

// jsdom (the fake browser Vitest runs in) doesn't implement window.matchMedia.
// Mock it so components like ThemeToggle that check prefers-color-scheme can mount.
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: (query) => ({
    matches: false, // tests default to light mode
    media: query,
    onchange: null,
    addListener: () => {}, // deprecated API, some libs still call it
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  }),
});
