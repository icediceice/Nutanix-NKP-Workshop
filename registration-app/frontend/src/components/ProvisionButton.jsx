import { useState } from 'react'
import { provisionAll, cleanupSessions } from '../api.js'
import { colors, styles, radius } from '../styles/theme.js'

export default function ProvisionButton({ onRefresh }) {
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState(null)

  const handleProvisionAll = async () => {
    if (!confirm('Provision all registered participants? This will request Educates workshop sessions for each.')) return
    setLoading(true)
    setResult(null)
    try {
      const { data } = await provisionAll()
      setResult({ type: 'success', message: data.message })
      setTimeout(onRefresh, 1500)
    } catch (err) {
      setResult({ type: 'error', message: err.response?.data?.detail || 'Provision failed.' })
    } finally {
      setLoading(false)
    }
  }

  const handleCleanup = async () => {
    if (!confirm('Delete all Educates workshop sessions and reset participant statuses to "registered"?')) return
    setLoading(true)
    try {
      const { data } = await cleanupSessions()
      setResult({ type: 'success', message: data.message })
      onRefresh()
    } catch (err) {
      setResult({ type: 'error', message: err.response?.data?.detail || 'Cleanup failed.' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap' }}>
      <button
        onClick={handleProvisionAll}
        disabled={loading}
        style={{ ...styles.btn.primary, opacity: loading ? 0.7 : 1 }}
      >
        {loading ? 'Working…' : 'Provision All'}
      </button>
      <button
        onClick={handleCleanup}
        disabled={loading}
        style={{ ...styles.btn.outline, color: '#D32F2F', borderColor: '#D32F2F' }}
      >
        Cleanup Sessions
      </button>
      {result && (
        <span style={{
          fontSize: '13px',
          color: result.type === 'success' ? '#2E7D32' : '#C62828',
          background: result.type === 'success' ? '#E8F5E9' : '#FFEBEE',
          padding: '6px 12px',
          borderRadius: radius.sm,
        }}>
          {result.message}
        </span>
      )}
    </div>
  )
}
