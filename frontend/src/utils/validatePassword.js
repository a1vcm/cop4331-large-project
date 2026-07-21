// Mirrors backend/utils/validatePassword.js — keep the rule in sync.
export const MIN_PASSWORD_LENGTH = 8;

export function isPasswordValid(password) {
  return typeof password === 'string' && password.length >= MIN_PASSWORD_LENGTH;
}
