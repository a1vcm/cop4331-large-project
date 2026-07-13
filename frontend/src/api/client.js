import axios from 'axios';

const TOKEN_KEY = 'knightrate_token';

const api = axios.create({ baseURL: '/api' });

// Guarded against environments where localStorage is missing or throws
// (private browsing, sandboxed iframes, some test environments).
function readStoredToken() {
  try {
    return typeof window !== 'undefined' ? window.localStorage.getItem(TOKEN_KEY) : null;
  } catch {
    return null;
  }
}

function writeStoredToken(token) {
  try {
    if (typeof window === 'undefined') return;
    if (token) window.localStorage.setItem(TOKEN_KEY, token);
    else window.localStorage.removeItem(TOKEN_KEY);
  } catch {
    // ignore — storage unavailable, token just won't persist across reloads
  }
}

export function setAuthToken(token) {
  if (token) {
    api.defaults.headers.common.Authorization = `Bearer ${token}`;
  } else {
    delete api.defaults.headers.common.Authorization;
  }
  writeStoredToken(token);
}

const existingToken = readStoredToken();
if (existingToken) setAuthToken(existingToken);

export function getErrorMessage(err, fallback = 'Something went wrong. Please try again.') {
  return err?.response?.data?.message || fallback;
}

export default api;
