import { colors, radius } from '../styles/theme.js'

function StatCard({ label, value, color }) {
  return (
    <div style={{
      background: '#fff',
      borderRadius: radius.md,
      padding: '16px 20px',
      borderLeft: `4px solid ${color || colors.primary}`,
      boxShadow: '0 1px 4px rgba(0,0,0,0.08)',
    }}>
      <div style={{ fontSize: '28px', fontWeight: 700, color: color || colors.primary }}>{value}</div>
      <div style={{ fontSize: '12px', color: '#888', marginTop: '2px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>{label}</div>
    </div>
  )
}

export default function StatsBar({ participants }) {
  const total = participants.length
  const registered = participants.filter((p) => p.status === 'registered').length
  const provisioning = participants.filter((p) => p.status === 'provisioning').length
  const ready = participants.filter((p) => p.status === 'ready').length
  const error = participants.filter((p) => p.status === 'error').length

  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: '12px', marginBottom: '24px' }}>
      <StatCard label="Total" value={total} color={colors.primary} />
      <StatCard label="Registered" value={registered} color="#1565C0" />
      <StatCard label="Provisioning" value={provisioning} color="#F57C00" />
      <StatCard label="Ready" value={ready} color="#2E7D32" />
      {error > 0 && <StatCard label="Error" value={error} color={colors.error || '#D32F2F'} />}
    </div>
  )
}
