import axios from 'axios';

const TOKEN_KEY = 'knightrate_token';
const USER_KEY = 'knightrate_user';

const api = axios.create({ baseURL: '/api' });

// Guarded against environments where localStorage is missing or throws
// (private browsing, sandboxed iframes, some test environments).
function readStorage(key) {
  try {
    return typeof window !== 'undefined' ? window.localStorage.getItem(key) : null;
  } catch {
    return null;
  }
}

function writeStorage(key, value) {
  try {
    if (typeof window === 'undefined') return;
    if (value) window.localStorage.setItem(key, value);
    else window.localStorage.removeItem(key);
  } catch {
    // ignore — storage unavailable, value just won't persist across reloads
  }
}

export function setAuthToken(token) {
  if (token) {
    api.defaults.headers.common.Authorization = `Bearer ${token}`;
  } else {
    delete api.defaults.headers.common.Authorization;
  }
  writeStorage(TOKEN_KEY, token);
}

// Stores the { id, username, email } that every auth endpoint returns
// alongside the token, so the UI can gate "write a review" and tell a
// user's own reviews apart without decoding the JWT.
export function setAuthUser(user) {
  writeStorage(USER_KEY, user ? JSON.stringify(user) : null);
}

export function getAuthUser() {
  const raw = readStorage(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function isLoggedIn() {
  return Boolean(readStorage(TOKEN_KEY));
}

export function clearAuthSession() {
  setAuthToken(null);
  setAuthUser(null);
}

const existingToken = readStorage(TOKEN_KEY);
if (existingToken) setAuthToken(existingToken);

export function getErrorMessage(err, fallback = 'Something went wrong. Please try again.') {
  return err?.response?.data?.message || fallback;
}

export default api;
