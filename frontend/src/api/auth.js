import api from './client';

export const register = (data) => api.post('/auth/register', data).then((r) => r.data);
export const verifyEmail = (data) => api.post('/auth/verify-email', data).then((r) => r.data);
export const resendVerification = (data) => api.post('/auth/resend-verification', data).then((r) => r.data);
export const login = (data) => api.post('/auth/login', data).then((r) => r.data);
export const forgotPassword = (data) => api.post('/auth/forgot-password', data).then((r) => r.data);
export const resetPassword = (data) => api.post('/auth/reset-password', data).then((r) => r.data);
