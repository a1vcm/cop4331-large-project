import api from './client';

// Account-management endpoints (backend: routes/users-routes.js).
//   PUT    /api/users/username        { username }                     -> { username }
//   POST   /api/users/email/request   { newEmail }                     -> { message } (sends code to newEmail)
//   POST   /api/users/email/verify    { code }                         -> { email }
//   PUT    /api/users/password        { currentPassword, newPassword } -> { message }
//   DELETE /api/users/me              { password }                     -> { message }
// All require the Authorization header (already attached by client.js).

export const changeUsername = (data) => api.put('/users/username', data).then((r) => r.data);
export const requestEmailChange = (data) => api.post('/users/email/request', data).then((r) => r.data);
export const verifyEmailChange = (data) => api.post('/users/email/verify', data).then((r) => r.data);
export const changePassword = (data) => api.put('/users/password', data).then((r) => r.data);
export const deleteAccount = (data) => api.delete('/users/me', { data }).then((r) => r.data);
