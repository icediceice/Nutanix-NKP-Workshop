import { useState, useEffect, useCallback } from 'react'
import { getParticipants, getActiveSession, exportCsv } from '../api.js'
import StatsBar from './StatsBar.jsx'
import ParticipantTable from './ParticipantTable.jsx'
import ProvisionButton from './ProvisionButton.jsx'
import ExcelImport from './ExcelImport.jsx'
import SessionManager from './SessionManager.jsx'
import ClusterOverview from './ClusterOverview.jsx'
import { colors, styles, radius, shadows } from '../styles/theme.js'

const TABS = ['Participants', 'Sessions', 'Cluster']

function Section({ title, children }) {
  return (
    <div style={{ background: '#fff', borderRadius: radius.md, boxShadow: shadows.card, padding: '20px', marginBottom: '20px' }}>
      {title && <h3 style={{ color: colors.primary, fontSize: '15px', marginBottom: '16px', fontWeight: 700 }}>{title}</h3>}
      {children}
    </div>
  )
}

export default function AdminPanel() {
  const [authed, setAuthed] = useState(!import.meta.env.PROD)  // skip auth in dev if no password set
  const [password, setPassword] = useState('')
  const [authError, setAuthError] = useState('')
  const [tab, setTab] = useState('Participants')
  const [participants, setParticipants] = useState([])
  const [activeSession, setActiveSession] = useState(null)
  const [loading, setLoading] = useState(false)

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

  useEffect(() => { loadParticipants() }, [authed])

  const handleAuth = (e) => {
    e.preventDefault()
    // Simple client-side check — real auth would be a backend endpoint
    const expectedPassword = window.__ADMIN_PASSWORD__ || ''
    if (!expectedPassword || password === expectedPassword) {
      setAuthed(true)
    } else {
      setAuthError('Incorrect password.')
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

  if (!authed) {
    return (
      <div style={{ maxWidth: '400px', margin: '60px auto' }}>
        <div style={{ ...styles.card, boxShadow: shadows.elevated }}>
          <h2 style={{ color: colors.primary, marginBottom: '20px' }}>Admin Login</h2>
          <form onSubmit={handleAuth}>
            <input
              type="password"
              style={{ ...styles.input, marginBottom: '16px' }}
              placeholder="Admin password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoFocus
            />
            {authError && <div style={{ color: '#C62828', fontSize: '13px', marginBottom: '12px' }}>{authError}</div>}
            <button type="submit" style={{ ...styles.btn.primary, width: '100%' }}>Sign In</button>
          </form>
        </div>
      </div>
    )
  }

  return (
    <div>
      {/* Active session banner */}
      {activeSession && (
        <div style={{ background: colors.primary, color: '#fff', borderRadius: radius.md, padding: '10px 20px', marginBottom: '20px', fontSize: '14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>Active Session: <strong>{activeSession.name}</strong></span>
          <span style={{ opacity: 0.7, fontSize: '12px' }}>
            {participants.length} participant{participants.length !== 1 ? 's' : ''}
          </span>
        </div>
      )}

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '4px', marginBottom: '20px', borderBottom: `2px solid ${colors.primary}` }}>
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            style={{
              padding: '8px 20px', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
              fontWeight: 600, fontSize: '14px', background: 'none',
              color: tab === t ? colors.primary : '#888',
              borderBottom: tab === t ? `3px solid ${colors.accent}` : '3px solid transparent',
              marginBottom: '-2px',
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
            <div style={{ display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap', marginBottom: '16px' }}>
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
            <ParticipantTable participants={participants} onRefresh={loadParticipants} />
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
