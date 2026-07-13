import api from './client';

export const getCourses = (q) => api.get('/courses', { params: q ? { q } : {} }).then((r) => r.data);
export const getCourseById = (id) => api.get(`/courses/${id}`).then((r) => r.data);
