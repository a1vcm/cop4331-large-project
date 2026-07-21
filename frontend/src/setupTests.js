import '@testing-library/jest-dom';

// Newer Node/jsdom combos don't reliably expose a working localStorage in
// the test environment (ThemeToggle reads it on mount). Simple in-memory
// stand-in so components that touch it don't crash during tests.
if (typeof window !== 'undefined' && (!window.localStorage || typeof window.localStorage.getItem !== 'function')) {
  let store = {};
  const localStorageMock = {
    getItem: (key) => (Object.prototype.hasOwnProperty.call(store, key) ? store[key] : null),
    setItem: (key, value) => { store[key] = String(value); },
    removeItem: (key) => { delete store[key]; },
    clear: () => { store = {}; },
  };
  Object.defineProperty(window, 'localStorage', { writable: true, value: localStorageMock });
}

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
