/// Mirrors backend/utils/validatePassword.js / frontend/src/utils/
/// validatePassword.js — keep the rule in sync.
const int kMinPasswordLength = 8;

bool isPasswordValid(String password) => password.length >= kMinPasswordLength;
