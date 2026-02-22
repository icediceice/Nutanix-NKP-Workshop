import axios from 'axios'

const api = axios.create({ baseURL: '/api' })

// --- Registration ---
export const register = (data) => api.post('/register', data)
export const getStatus = (email) => api.get(`/status/${encodeURIComponent(email)}`)

// --- Courses ---
export const getCourses = () => api.get('/courses')

// --- Participants (admin) ---
export const getParticipants = (params = {}) => api.get('/participants', { params })
export const deleteParticipant = (id) => api.delete(`/participants/${id}`)

// --- Sessions (admin) ---
export const getSessions = () => api.get('/sessions')
export const getActiveSession = () => api.get('/sessions/active')
export const createSession = (data) => api.post('/sessions', data)
export const updateSession = (id, data) => api.put(`/sessions/${id}`, data)
export const activateSession = (id) => api.put(`/sessions/${id}/activate`)
export const archiveSession = (id) => api.delete(`/sessions/${id}`)

// --- Provisioning (admin) ---
export const provisionAll = () => api.post('/provision')
export const provisionOne = (id) => api.post(`/provision/${id}`)
export const cleanupSessions = () => api.post('/cleanup')
export const getClusterStatus = () => api.get('/cluster/status')

// --- Import / Export ---
export const importExcel = (formData) =>
  api.post('/import', formData, { headers: { 'Content-Type': 'multipart/form-data' } })
export const getImportTemplate = () =>
  api.get('/import/template', { responseType: 'blob' })
export const exportCsv = (sessionId) =>
  api.get('/export/csv', { params: sessionId ? { session_id: sessionId } : {}, responseType: 'blob' })
