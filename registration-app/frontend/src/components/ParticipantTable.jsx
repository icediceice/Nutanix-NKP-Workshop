import { useState } from 'react'
import { deleteParticipant, provisionOne } from '../api.js'
import { colors, styles, radius } from '../styles/theme.js'

const STATUS_BADGE = {
  registered: { bg: '#E3F2FD', color: '#1565C0', label: 'Registered' },
  provisioning: { bg: '#FFF8E1', color: '#F57C00', label: 'Provisioning' },
  ready: { bg: '#E8F5E9', color: '#2E7D32', label: 'Ready' },
  error: { bg: '#FFEBEE', color: '#C62828', label: 'Error' },
}

function Badge({ status }) {
  const s = STATUS_BADGE[status] || { bg: '#eee', color: '#555', label: status }
  return (
    <span style={{ background: s.bg, color: s.color, padding: '2px 10px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 }}>
      {s.label}
    </span>
  )
}

export default function ParticipantTable({ participants, onRefresh }) {
  const [expanded, setExpanded] = useState(null)

  const handleDelete = async (id, name) => {
    if (!confirm(`Remove ${name}?`)) return
    await deleteParticipant(id)
    onRefresh()
  }

  const handleProvision = async (id) => {
    await provisionOne(id)
    onRefresh()
  }

  if (!participants.length) {
    return (
      <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
        No participants yet. Share the registration URL or import from Excel.
      </div>
    )
  }

  return (
    <div style={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px' }}>
        <thead>
          <tr style={{ borderBottom: `2px solid ${colors.primary}` }}>
            {['Name', 'Email', 'Company', 'Modules', 'Status', 'Actions'].map((h) => (
              <th key={h} style={{ padding: '10px 12px', textAlign: 'left', fontWeight: 700, color: colors.primary, fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {participants.map((p) => (
            <>
              <tr
                key={p.id}
                style={{ borderBottom: '1px solid #F0F0F0', cursor: p.status === 'ready' ? 'pointer' : 'default' }}
                onClick={() => p.status === 'ready' && setExpanded(expanded === p.id ? null : p.id)}
              >
                <td style={{ padding: '10px 12px', fontWeight: 600 }}>{p.name}</td>
                <td style={{ padding: '10px 12px', color: '#555' }}>{p.email}</td>
                <td style={{ padding: '10px 12px', color: '#555' }}>{p.company || '—'}</td>
                <td style={{ padding: '10px 12px' }}>
                  {(() => {
                    const mods = p.modules ? JSON.parse(p.modules) : []
                    return mods.length > 0
                      ? <span style={{ fontSize: '11px', color: '#555' }}>{mods.join(', ')}</span>
                      : <span style={{ color: '#bbb' }}>—</span>
                  })()}
                </td>
                <td style={{ padding: '10px 12px' }}><Badge status={p.status} /></td>
                <td style={{ padding: '10px 12px' }}>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    {(p.status === 'registered' || p.status === 'error') && (
                      <button onClick={(e) => { e.stopPropagation(); handleProvision(p.id) }} style={{ ...styles.btn.accent, padding: '4px 10px', fontSize: '12px' }}>
                        Provision
                      </button>
                    )}
                    <button onClick={(e) => { e.stopPropagation(); handleDelete(p.id, p.name) }} style={{ ...styles.btn.outline, padding: '4px 10px', fontSize: '12px', color: '#D32F2F', borderColor: '#D32F2F' }}>
                      Remove
                    </button>
                  </div>
                </td>
              </tr>
              {expanded === p.id && p.workshop_urls && (
                <tr key={`${p.id}-expanded`} style={{ background: '#F8F6FF' }}>
                  <td colSpan={6} style={{ padding: '12px 24px' }}>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: colors.primary, marginBottom: '8px' }}>Workshop URLs</div>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '8px' }}>
                      {Object.entries(JSON.parse(p.workshop_urls)).map(([id, url]) => (
                        <div key={id} style={{ background: '#fff', borderRadius: radius.sm, padding: '8px 12px', border: '1px solid #E0E0E0' }}>
                          <div style={{ fontSize: '11px', fontWeight: 700, color: '#666', textTransform: 'uppercase', marginBottom: '4px' }}>{id}</div>
                          <a href={url} target="_blank" rel="noreferrer" style={{ color: colors.accent, fontSize: '12px', wordBreak: 'break-all' }}>{url}</a>
                        </div>
                      ))}
                    </div>
                    {p.error_message && (
                      <div style={{ marginTop: '8px', color: '#C62828', fontSize: '12px' }}>Error: {p.error_message}</div>
                    )}
                  </td>
                </tr>
              )}
            </>
          ))}
        </tbody>
      </table>
    </div>
  )
}
