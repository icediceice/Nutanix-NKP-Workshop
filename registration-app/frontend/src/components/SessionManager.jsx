import { useState, useEffect } from 'react'
import { getSessions, createSession, updateSession, activateSession, archiveSession } from '../api.js'
import { colors, styles, radius } from '../styles/theme.js'

const STATUS_COLOR = { active: '#2E7D32', completed: '#888', archived: '#bbb' }

function EditSessionModal({ session, onSave, onClose }) {
  const [name, setName] = useState(session.name)
  const [eventDate, setEventDate] = useState(session.event_date || '')
  const [saving, setSaving] = useState(false)

  const handleSave = async () => {
    setSaving(true)
    try {
      await onSave(session.id, { name: name.trim() || session.name, event_date: eventDate || null })
    } finally {
      setSaving(false)
    }
  }

  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000,
    }}>
      <div style={{ background: '#fff', borderRadius: radius.lg, padding: '28px', width: '400px', boxShadow: '0 8px 32px rgba(0,0,0,0.18)' }}>
        <h3 style={{ color: colors.primary, marginBottom: '20px', fontSize: '16px' }}>Edit Session</h3>

        <div style={{ marginBottom: '16px' }}>
          <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>Session Name</label>
          <input
            style={styles.input}
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Partner Workshop March 2026"
          />
        </div>

        <div style={{ marginBottom: '24px' }}>
          <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>Event Date</label>
          <input
            style={styles.input}
            type="date"
            value={eventDate}
            onChange={(e) => setEventDate(e.target.value)}
          />
        </div>

        <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
          <button onClick={onClose} style={{ ...styles.btn.outline, padding: '8px 16px' }}>Cancel</button>
          <button onClick={handleSave} disabled={saving} style={{ ...styles.btn.primary, padding: '8px 16px', opacity: saving ? 0.7 : 1 }}>
            {saving ? 'Saving…' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  )
}

export default function SessionManager({ onSessionChange }) {
  const [sessions, setSessions] = useState([])
  const [newName, setNewName] = useState('')
  const [newEventDate, setNewEventDate] = useState('')
  const [creating, setCreating] = useState(false)
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState(null)

  const load = async () => {
    try {
      const { data } = await getSessions()
      setSessions(data)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  const handleCreate = async (e) => {
    e.preventDefault()
    if (!newName.trim()) return
    setCreating(true)
    try {
      await createSession({ name: newName.trim(), event_date: newEventDate || null })
      setNewName('')
      setNewEventDate('')
      await load()
      onSessionChange?.()
    } finally {
      setCreating(false)
    }
  }

  const handleUpdate = async (id, data) => {
    await updateSession(id, data)
    setEditing(null)
    await load()
    onSessionChange?.()
  }

  const handleActivate = async (id) => {
    await activateSession(id)
    await load()
    onSessionChange?.()
  }

  const handleArchive = async (id) => {
    if (!confirm('Archive this session?')) return
    await archiveSession(id)
    await load()
    onSessionChange?.()
  }

  if (loading) return <div style={{ color: '#999', fontSize: '14px' }}>Loading sessions…</div>

  return (
    <div>
      {editing && (
        <EditSessionModal
          session={editing}
          onSave={handleUpdate}
          onClose={() => setEditing(null)}
        />
      )}

      <form onSubmit={handleCreate} style={{ display: 'flex', gap: '10px', marginBottom: '16px', flexWrap: 'wrap' }}>
        <input
          style={{ ...styles.input, flex: '2 1 200px' }}
          placeholder="Session name (e.g. Partner Workshop March 2026)"
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
          required
        />
        <input
          style={{ ...styles.input, flex: '1 1 140px' }}
          type="date"
          value={newEventDate}
          onChange={(e) => setNewEventDate(e.target.value)}
          title="Event date (optional)"
        />
        <button type="submit" disabled={creating} style={{ ...styles.btn.primary, whiteSpace: 'nowrap' }}>
          {creating ? 'Creating…' : '+ New Session'}
        </button>
      </form>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
        {sessions.map((s) => (
          <div
            key={s.id}
            style={{
              display: 'flex', alignItems: 'center', gap: '10px',
              padding: '10px 14px', borderRadius: radius.sm,
              border: `1px solid ${s.status === 'active' ? colors.spark : '#E0E0E0'}`,
              background: s.status === 'active' ? '#F0FFFE' : '#FAFAFA',
              flexWrap: 'wrap',
            }}
          >
            <span style={{ flex: 1, fontWeight: s.status === 'active' ? 700 : 400, fontSize: '14px' }}>
              {s.name}
              {s.event_date && (
                <span style={{ fontSize: '12px', color: '#999', fontWeight: 400, marginLeft: '8px' }}>
                  {new Date(s.event_date + 'T00:00:00').toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
                </span>
              )}
            </span>
            <span style={{ fontSize: '11px', fontWeight: 700, color: STATUS_COLOR[s.status] || '#888', textTransform: 'uppercase' }}>
              {s.status}
            </span>
            <span style={{ fontSize: '12px', color: '#aaa' }}>
              Created {new Date(s.created_at).toLocaleDateString()}
            </span>
            <button
              onClick={() => setEditing(s)}
              style={{ ...styles.btn.outline, padding: '4px 10px', fontSize: '12px' }}
              title="Edit session name / date"
            >
              Edit
            </button>
            {s.status !== 'active' && (
              <button onClick={() => handleActivate(s.id)} style={{ ...styles.btn.accent, padding: '4px 10px', fontSize: '12px' }}>
                Activate
              </button>
            )}
            {s.status !== 'archived' && (
              <button onClick={() => handleArchive(s.id)} style={{ ...styles.btn.outline, padding: '4px 10px', fontSize: '12px', color: '#d32f2f', borderColor: '#d32f2f' }}>
                Archive
              </button>
            )}
          </div>
        ))}
        {!sessions.length && (
          <div style={{ color: '#999', fontSize: '14px' }}>No sessions yet. Create one to get started.</div>
        )}
      </div>
    </div>
  )
}
