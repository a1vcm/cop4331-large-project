import api from './client';

export const getCourseReviews = (courseId) => api.get(`/reviews/course/${courseId}`).then((r) => r.data);
export const getMyReviews = () => api.get('/reviews/mine').then((r) => r.data);
export const createReview = (data) => api.post('/reviews', data).then((r) => r.data);
export const updateReview = (id, data) => api.put(`/reviews/${id}`, data).then((r) => r.data);
export const deleteReview = (id) => api.delete(`/reviews/${id}`).then((r) => r.data);
