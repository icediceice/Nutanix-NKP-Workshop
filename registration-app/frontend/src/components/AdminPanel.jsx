import { useState, useEffect, useCallback } from 'react'
import { getParticipants, getActiveSession, exportCsv, verifyAdmin } from '../api.js'
import StatsBar from './StatsBar.jsx'
import ParticipantTable from './ParticipantTable.jsx'
import ProvisionButton from './ProvisionButton.jsx'
import ExcelImport from './ExcelImport.jsx'
import SessionManager from './SessionManager.jsx'
import ClusterOverview from './ClusterOverview.jsx'
import { colors, styles, radius, shadows } from '../styles/theme.js'

const TABS = ['Participants', 'Sessions', 'Cluster']
const STATUS_OPTIONS = ['', 'registered', 'provisioning', 'ready', 'error']

function Section({ title, children }) {
  return (
    <div style={{ background: colors.surface, borderRadius: radius.md, border: `1px solid ${colors.border}`, padding: '20px', marginBottom: '20px' }}>
      {title && <h3 style={{ color: colors.accent, fontSize: '15px', marginBottom: '16px', fontWeight: 700 }}>{title}</h3>}
      {children}
    </div>
  )
}

export default function AdminPanel() {
  const [authed, setAuthed] = useState(false)
  const [password, setPassword] = useState('')
  const [authError, setAuthError] = useState('')
  const [authLoading, setAuthLoading] = useState(false)
  const [tab, setTab] = useState('Participants')
  const [participants, setParticipants] = useState([])
  const [activeSession, setActiveSession] = useState(null)
  const [loading, setLoading] = useState(false)
  const [search, setSearch] = useState('')
  const [filterStatus, setFilterStatus] = useState('')

  const loadParticipants = useCallback(async () => {
    if (!authed) return
    setLoading(true)
    try {
      const [pRes, sRes] = await Promise.allSettled([
        getParticipants(activeSession ? { session_id: activeSession.id } : {}),
        getActiveSession(),
      ])
      if (pRes.status === 'fulfilled') setParticipants(pRes.value.data)
      if (sRes.status === 'fulfilled') setActiveSession(sRes.value.data)
    } finally {
      setLoading(false)
    }
  }, [authed, activeSession?.id])

  useEffect(() => { if (authed) loadParticipants() }, [authed])

  const handleAuth = async (e) => {
    e.preventDefault()
    setAuthLoading(true)
    setAuthError('')
    try {
      await verifyAdmin(password)
      setAuthed(true)
    } catch (err) {
      setAuthError(err.response?.data?.detail || 'Incorrect password.')
    } finally {
      setAuthLoading(false)
    }
  }

  const handleExport = async () => {
    const { data } = await exportCsv(activeSession?.id)
    const url = URL.createObjectURL(new Blob([data], { type: 'text/csv' }))
    const a = document.createElement('a')
    a.href = url
    a.download = `participants-${activeSession?.name || 'export'}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }

  const filteredParticipants = participants.filter((p) => {
    const q = search.toLowerCase()
    const matchSearch = !q || [p.name, p.email, p.company].some((f) => f?.toLowerCase().includes(q))
    const matchStatus = !filterStatus || p.status === filterStatus
    return matchSearch && matchStatus
  })

  if (!authed) {
    return (
      <div style={{ maxWidth: '400px', margin: '60px auto' }}>
        <div style={{ ...styles.card, boxShadow: shadows.elevated }}>
          <h2 style={{ color: colors.accent, marginBottom: '8px' }}>Admin Login</h2>
          <p style={{ fontSize: '13px', color: colors.textSecondary, marginBottom: '20px' }}>
            Leave blank and press Sign In if no password is set (local dev).
          </p>
          <form onSubmit={handleAuth}>
            <input
              type="password"
              style={{ ...styles.input, marginBottom: '16px' }}
              placeholder="Admin password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoFocus
            />
            {authError && <div style={{ color: colors.error, fontSize: '13px', marginBottom: '12px' }}>{authError}</div>}
            <button type="submit" disabled={authLoading} style={{ ...styles.btn.primary, width: '100%', opacity: authLoading ? 0.7 : 1 }}>
              {authLoading ? 'Checking…' : 'Sign In'}
            </button>
          </form>
        </div>
      </div>
    )
  }

  return (
    <div>
      {activeSession && (
        <div style={{ background: colors.elevated, border: `1px solid ${colors.primary}44`, borderLeft: `4px solid ${colors.primary}`, borderRadius: radius.md, padding: '10px 20px', marginBottom: '20px', fontSize: '14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>
            Active Session: <strong style={{ color: colors.accent }}>{activeSession.name}</strong>
            {activeSession.event_date && (
              <span style={{ color: colors.textSecondary, marginLeft: '10px', fontSize: '12px' }}>
                {new Date(activeSession.event_date + 'T00:00:00').toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
              </span>
            )}
          </span>
          <span style={{ color: colors.textSecondary, fontSize: '12px' }}>
            {participants.length} participant{participants.length !== 1 ? 's' : ''}
          </span>
        </div>
      )}

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '4px', marginBottom: '20px', borderBottom: `1px solid ${colors.border}` }}>
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            style={{
              padding: '8px 20px', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
              fontWeight: 600, fontSize: '14px', background: 'none',
              color: tab === t ? colors.accent : colors.textSecondary,
              borderBottom: tab === t ? `2px solid ${colors.accent}` : '2px solid transparent',
              marginBottom: '-1px',
            }}
          >
            {t}
          </button>
        ))}
      </div>

      {tab === 'Participants' && (
        <>
          <StatsBar participants={participants} />
          <Section>
            <div style={{ display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap', marginBottom: '16px' }}>
              <input
                style={{ ...styles.input, flex: '2 1 200px', marginBottom: 0 }}
                placeholder="Search name, email, company…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
              <select
                style={{ ...styles.input, flex: '0 0 140px', marginBottom: 0 }}
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
              >
                {STATUS_OPTIONS.map((s) => (
                  <option key={s} value={s}>{s || 'All statuses'}</option>
                ))}
              </select>
              <ProvisionButton onRefresh={loadParticipants} />
              <div style={{ marginLeft: 'auto', display: 'flex', gap: '8px' }}>
                <ExcelImport onImported={loadParticipants} />
                <button onClick={handleExport} style={{ ...styles.btn.outline, fontSize: '13px' }}>
                  ↓ Export CSV
                </button>
                <button onClick={loadParticipants} style={{ ...styles.btn.outline, fontSize: '13px' }}>
                  {loading ? '…' : '↻ Refresh'}
                </button>
              </div>
            </div>

            {(search || filterStatus) ? (
              <div style={{ fontSize: '12px', color: colors.textSecondary, marginBottom: '10px' }}>
                Showing {filteredParticipants.length} of {participants.length} participants
                <button
                  onClick={() => { setSearch(''); setFilterStatus('') }}
                  style={{ marginLeft: '10px', background: 'none', border: 'none', color: colors.accent, cursor: 'pointer', fontSize: '12px', textDecoration: 'underline' }}
                >
                  Clear filters
                </button>
              </div>
            ) : null}

            <ParticipantTable participants={filteredParticipants} onRefresh={loadParticipants} />
          </Section>
        </>
      )}

      {tab === 'Sessions' && (
        <Section title="Session Management">
          <SessionManager onSessionChange={loadParticipants} />
        </Section>
      )}

      {tab === 'Cluster' && (
        <Section title="Cluster & Educates Health">
          <ClusterOverview />
        </Section>
      )}
    </div>
  )
}
