import { colors, radius } from '../styles/theme.js'

function StatCard({ label, value, color }) {
  return (
    <div style={{
      background: colors.surface,
      borderRadius: radius.md,
      padding: '16px 20px',
      borderLeft: `4px solid ${color || colors.primary}`,
      border: `1px solid ${colors.border}`,
      borderLeftColor: color || colors.primary,
    }}>
      <div style={{ fontSize: '28px', fontWeight: 700, color: color || colors.primary }}>{value}</div>
      <div style={{ fontSize: '12px', color: colors.textSecondary, marginTop: '2px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>{label}</div>
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
      <StatCard label="Registered" value={registered} color={colors.info} />
      <StatCard label="Provisioning" value={provisioning} color={colors.warning} />
      <StatCard label="Ready" value={ready} color={colors.success} />
      {error > 0 && <StatCard label="Error" value={error} color={colors.error} />}
    </div>
  )
}
