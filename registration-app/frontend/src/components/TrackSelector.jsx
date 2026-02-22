import { colors, radius } from '../styles/theme.js'

const TRACKS = [
  {
    id: 'developer',
    label: 'Developer Track',
    sublabel: 'Cloud Native Developer',
    description: 'Build and deploy cloud-native applications on Kubernetes',
    color: colors.accent,
    modules: ['Intro to Kubernetes', 'Twelve-Factor App', 'Containers with Docker', 'K8s Architecture', 'App Development (GitOps, .NET, CI/CD)', 'NKP Developer Platform (Harbor, FluxCD, Istio)'],
  },
  {
    id: 'infrastructure',
    label: 'Infrastructure Track',
    sublabel: 'Cloud Native Infrastructure',
    description: 'Manage and operate the Kubernetes platform and infrastructure',
    color: colors.spark,
    modules: ['Intro to Kubernetes', 'Twelve-Factor App', 'Containers with Docker', 'K8s Architecture', 'Infra Introduction (CAPI, NKP)', 'NKP Infrastructure Platform (workspaces, backup, RBAC)'],
  },
]

export default function TrackSelector({ value, onChange }) {
  return (
    <div>
      <label style={{ display: 'block', fontWeight: 600, fontSize: '14px', marginBottom: '12px', color: colors.dark }}>
        Select your track <span style={{ color: 'red' }}>*</span>
      </label>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
        {TRACKS.map((track) => {
          const selected = value === track.id
          return (
            <button
              key={track.id}
              type="button"
              onClick={() => onChange(track.id)}
              style={{
                border: `2px solid ${selected ? track.color : '#E0E0E0'}`,
                borderRadius: radius.md,
                padding: '16px',
                background: selected ? `${track.color}18` : '#fff',
                cursor: 'pointer',
                textAlign: 'left',
                transition: 'all 0.15s',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
                <span
                  style={{
                    width: '18px', height: '18px', borderRadius: '50%',
                    border: `2px solid ${track.color}`,
                    background: selected ? track.color : 'transparent',
                    display: 'inline-block', flexShrink: 0,
                  }}
                />
                <span style={{ fontWeight: 700, fontSize: '15px', color: colors.dark }}>{track.label}</span>
              </div>
              <div style={{ fontSize: '12px', color: track.color, fontWeight: 600, marginBottom: '8px', marginLeft: '26px' }}>
                {track.sublabel}
              </div>
              <div style={{ fontSize: '13px', color: '#555', marginBottom: '10px', marginLeft: '26px' }}>
                {track.description}
              </div>
              <ul style={{ marginLeft: '26px', paddingLeft: '14px', fontSize: '12px', color: '#666' }}>
                {track.modules.map((m) => (
                  <li key={m} style={{ marginBottom: '2px' }}>{m}</li>
                ))}
              </ul>
            </button>
          )
        })}
      </div>
      <div style={{ fontSize: '12px', color: '#888', marginTop: '8px' }}>
        Foundation modules (Intro to K8s, Twelve-Factor, Containers, K8s Architecture) are included in both tracks.
      </div>
    </div>
  )
}
