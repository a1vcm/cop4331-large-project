import api from './client';

export const getCourses = (q, opts = {}) =>
  api.get('/courses', { params: { ...(q ? { q } : {}), ...opts } }).then((r) => r.data);
export const getCourseById = (id) => api.get(`/courses/${id}`).then((r) => r.data);
