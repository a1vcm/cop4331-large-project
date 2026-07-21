import api from './client';

export const getCourseResources = (courseId) => api.get(`/resources/course/${courseId}`).then((r) => r.data);
export const createResource = (data) => api.post('/resources', data).then((r) => r.data);
export const deleteResource = (id) => api.delete(`/resources/${id}`).then((r) => r.data);
