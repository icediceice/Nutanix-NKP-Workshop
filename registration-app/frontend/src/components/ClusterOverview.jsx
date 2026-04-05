import { useState, useEffect } from 'react'
import { getClusterStatus } from '../api.js'
import { colors, radius } from '../styles/theme.js'

function Row({ label, value, mono }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: `1px solid ${colors.border}`, fontSize: '13px' }}>
      <span style={{ color: colors.textSecondary }}>{label}</span>
      <span style={{ fontWeight: 600, fontFamily: mono ? 'monospace' : 'inherit', color: colors.textPrimary }}>{value}</span>
    </div>
  )
}

export default function ClusterOverview() {
  const [status, setStatus] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const load = async () => {
    setLoading(true)
    try {
      const { data } = await getClusterStatus()
      setStatus(data)
      setError('')
    } catch {
      setError('Could not reach cluster status endpoint.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  if (loading) return <div style={{ color: colors.textSecondary, fontSize: '14px' }}>Checking cluster…</div>
  if (error) return <div style={{ color: colors.error, fontSize: '14px' }}>{error}</div>

  const modeColor = status?.mode === 'dry_run' ? colors.warning : status?.mode === 'live' ? colors.success : colors.error

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
        <span style={{ fontWeight: 700, fontSize: '14px', color: colors.textPrimary }}>Cluster Status</span>
        <span style={{ background: `${modeColor}22`, color: modeColor, border: `1px solid ${modeColor}44`, fontSize: '11px', fontWeight: 700, padding: '2px 8px', borderRadius: '12px', textTransform: 'uppercase' }}>
          {status?.mode}
        </span>
        <button onClick={load} style={{ marginLeft: 'auto', fontSize: '12px', cursor: 'pointer', color: colors.accent, background: 'none', border: 'none' }}>
          ↻ Refresh
        </button>
      </div>

      {status?.message && (
        <div style={{ fontSize: '12px', color: colors.warning, background: colors.warningBg, border: `1px solid ${colors.warning}33`, borderRadius: radius.sm, padding: '8px 12px', marginBottom: '10px' }}>
          {status.message}
        </div>
      )}

      <Row label="Cluster UID" value={status?.cluster_uid || '—'} mono />
      {status?.nodes && (
        <Row label="Nodes" value={`${status.nodes.ready} / ${status.nodes.total} Ready`} />
      )}
      {status?.educates && (
        <Row label="Educates" value={status.educates.status} />
      )}
    </div>
  )
}
