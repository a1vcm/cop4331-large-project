import api from './client';

export const getMyBookmarks = () => api.get('/bookmarks/mine').then((r) => r.data);
export const createBookmark = (reviewId) => api.post('/bookmarks', { reviewId }).then((r) => r.data);
export const deleteBookmark = (reviewId) => api.delete(`/bookmarks/${reviewId}`).then((r) => r.data);
