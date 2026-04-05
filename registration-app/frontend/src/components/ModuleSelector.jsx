import { useState, useEffect } from 'react'
import { getCourses } from '../api.js'
import { colors, radius } from '../styles/theme.js'

const CATEGORY_LABELS = {
  developer: { label: 'Developer', color: colors.accent },
  infrastructure: { label: 'Infrastructure', color: colors.spark },
}

export default function ModuleSelector({ value = [], onChange, onCoursesLoaded }) {
  const [bundles, setBundles] = useState({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getCourses()
      .then(({ data }) => {
        setBundles(data.bundles || {})
        onCoursesLoaded?.(data)
      })
      .catch(() => setBundles({}))
      .finally(() => setLoading(false))
  }, [])

  const toggle = (id) => {
    const next = value.includes(id) ? value.filter((v) => v !== id) : [...value, id]
    onChange(next)
  }

  if (loading) return <div style={{ color: colors.textSecondary, fontSize: '14px' }}>Loading modules…</div>

  const grouped = {}
  for (const [id, bundle] of Object.entries(bundles)) {
    const cat = bundle.category || 'other'
    if (!grouped[cat]) grouped[cat] = []
    grouped[cat].push({ id, ...bundle })
  }

  return (
    <div>
      <label style={{ display: 'block', fontWeight: 600, fontSize: '14px', marginBottom: '6px', color: colors.textPrimary }}>
        Learning Modules <span style={{ color: colors.error }}>*</span>
      </label>
      <p style={{ fontSize: '12px', color: colors.textSecondary, marginBottom: '14px' }}>
        Foundation workshops (Intro to K8s, Twelve-Factor, Containers, K8s Architecture) are included for all participants.
        Select the additional topics you want to learn — you can mix developer and infrastructure modules.
      </p>

      {Object.entries(grouped).map(([category, items]) => {
        const cat = CATEGORY_LABELS[category] || { label: category, color: colors.textSecondary }
        return (
          <div key={category} style={{ marginBottom: '20px' }}>
            <div style={{
              fontSize: '11px', fontWeight: 700, letterSpacing: '1px', textTransform: 'uppercase',
              color: cat.color, marginBottom: '10px', paddingBottom: '6px',
              borderBottom: `2px solid ${cat.color}33`,
            }}>
              {cat.label}
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: '10px' }}>
              {items.map((bundle) => {
                const selected = value.includes(bundle.id)
                return (
                  <button
                    key={bundle.id}
                    type="button"
                    onClick={() => toggle(bundle.id)}
                    style={{
                      border: `2px solid ${selected ? cat.color : colors.border}`,
                      borderRadius: radius.md,
                      padding: '12px 14px',
                      background: selected ? `${cat.color}18` : colors.elevated,
                      cursor: 'pointer',
                      textAlign: 'left',
                      transition: 'all 0.15s',
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'flex-start', gap: '10px' }}>
                      <div style={{
                        width: '18px', height: '18px', borderRadius: '4px', flexShrink: 0, marginTop: '2px',
                        border: `2px solid ${cat.color}`,
                        background: selected ? cat.color : 'transparent',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>
                        {selected && <span style={{ color: '#fff', fontSize: '12px', fontWeight: 700 }}>✓</span>}
                      </div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontWeight: 700, fontSize: '13px', color: colors.textPrimary, marginBottom: '3px' }}>
                          {bundle.title}
                        </div>
                        {bundle.duration_hours && (
                          <div style={{ fontSize: '11px', color: cat.color, fontWeight: 600, marginBottom: '4px' }}>
                            {bundle.duration_hours}h
                          </div>
                        )}
                        <div style={{ fontSize: '12px', color: colors.textSecondary, lineHeight: 1.4, marginBottom: bundle.includes_tools ? '6px' : 0 }}>
                          {bundle.description}
                        </div>
                        {bundle.includes_tools && (
                          <div style={{ fontSize: '11px', color: colors.textMuted, marginTop: '4px' }}>
                            Includes: {bundle.includes_tools.join(' · ')}
                          </div>
                        )}
                        {bundle.coherent_with && (
                          <div style={{ fontSize: '11px', color: colors.textMuted, marginTop: '3px', fontStyle: 'italic' }}>
                            Pairs well with: {bundle.coherent_with.join(', ')}
                          </div>
                        )}
                      </div>
                    </div>
                  </button>
                )
              })}
            </div>
          </div>
        )
      })}

      {value.length > 0 && (
        <div style={{ marginTop: '12px', fontSize: '12px', color: colors.accent }}>
          Selected: <strong>{value.length}</strong> module{value.length !== 1 ? 's' : ''} — {value.join(', ')}
        </div>
      )}
    </div>
  )
}
