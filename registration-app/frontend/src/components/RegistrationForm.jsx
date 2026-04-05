import { useState } from 'react'
import { register } from '../api.js'
import ModuleSelector from './ModuleSelector.jsx'
import { colors, styles, shadows, radius } from '../styles/theme.js'

export default function RegistrationForm() {
  const [form, setForm] = useState({ name: '', email: '', company: '', modules: [] })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(null)
  const [courses, setCourses] = useState(null)

  const handleChange = (field) => (e) => setForm((f) => ({ ...f, [field]: e.target.value }))

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    if (form.modules.length === 0) { setError('Please select at least one learning module.'); return }

    setLoading(true)
    try {
      const { data } = await register(form)
      setSuccess(data)
    } catch (err) {
      setError(err.response?.data?.detail || 'Registration failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div style={{ maxWidth: '600px', margin: '0 auto' }}>
        <div style={{ ...styles.card, borderTop: `4px solid ${colors.spark}`, textAlign: 'center' }}>
          <div style={{ fontSize: '48px', marginBottom: '12px' }}>✓</div>
          <h2 style={{ color: colors.primary, marginBottom: '8px' }}>Registration Successful!</h2>
          <p style={{ color: '#555', marginBottom: '24px' }}>
            Welcome, <strong>{success.participant.name}</strong>. You are registered for the{' '}
            <strong>{success.participant.session}</strong> session.
          </p>
          <div style={{ background: colors.lightGray, borderRadius: radius.md, padding: '16px', textAlign: 'left' }}>
            <div style={{ fontSize: '13px', color: '#555', marginBottom: '4px' }}>Your username:</div>
            <div style={{ fontWeight: 700, fontSize: '18px', color: colors.primary, fontFamily: 'monospace' }}>
              {success.participant.username}
            </div>
            {success.participant.modules?.length > 0 && (
              <div style={{ fontSize: '12px', color: '#888', marginTop: '8px' }}>
                Modules: {success.participant.modules.join(', ')}
              </div>
            )}
          </div>
          <p style={{ fontSize: '13px', color: '#888', marginTop: '16px' }}>
            Your trainer will provision your workshop environments and share the access links.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto' }}>
      {/* Certificate setup notice */}
      <div style={{
        background: '#EFF6FF',
        border: '1px solid #BFDBFE',
        borderLeft: '4px solid #3B82F6',
        borderRadius: radius.md,
        padding: '14px 18px',
        marginBottom: '20px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: '12px',
        flexWrap: 'wrap',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '20px' }}>&#128274;</span>
          <div>
            <div style={{ fontWeight: 700, fontSize: '14px', color: '#1E40AF' }}>First time? Install the cluster certificate</div>
            <div style={{ fontSize: '13px', color: '#3B82F6', marginTop: '2px' }}>Required so workshop links load in your browser. Takes 2 minutes.</div>
          </div>
        </div>
        <a href="/setup" style={{
          background: '#3B82F6',
          color: '#fff',
          padding: '8px 16px',
          borderRadius: radius.sm,
          fontWeight: 600,
          fontSize: '13px',
          textDecoration: 'none',
          whiteSpace: 'nowrap',
        }}>
          Setup Guide &rarr;
        </a>
      </div>

      <div style={{ ...styles.card, boxShadow: shadows.elevated }}>
        <h1 style={{ color: colors.primary, fontSize: '24px', marginBottom: '4px' }}>
          Workshop Registration
        </h1>
        <p style={{ color: '#666', fontSize: '14px', marginBottom: '28px' }}>
          Register to get access to your hands-on lab environments.
        </p>

        <form onSubmit={handleSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '16px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
                Full Name <span style={{ color: 'red' }}>*</span>
              </label>
              <input
                style={styles.input}
                type="text"
                placeholder="Alex Chen"
                value={form.name}
                onChange={handleChange('name')}
                required
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
                Email <span style={{ color: 'red' }}>*</span>
              </label>
              <input
                style={styles.input}
                type="email"
                placeholder="you@company.com"
                value={form.email}
                onChange={handleChange('email')}
                required
              />
            </div>
          </div>

          <div style={{ marginBottom: '24px' }}>
            <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
              Company
            </label>
            <input
              style={styles.input}
              type="text"
              placeholder="Acme Corp"
              value={form.company}
              onChange={handleChange('company')}
            />
          </div>

          <div style={{ marginBottom: form.modules.length > 0 ? '16px' : '28px' }}>
            <ModuleSelector
              value={form.modules}
              onChange={(modules) => setForm((f) => ({ ...f, modules }))}
              onCoursesLoaded={setCourses}
            />
          </div>

          {form.modules.length > 0 && courses && (() => {
            const bundles = courses.bundles || {}
            const foundation = courses.foundation || {}
            const foundationCount = (foundation.workshops || []).length
            const totalHours = form.modules.reduce((sum, id) => sum + (bundles[id]?.duration_hours || 0), 0)
            const uniqueWorkshops = new Set([
              ...(foundation.workshops || []),
              ...form.modules.flatMap((id) => bundles[id]?.workshops || []),
            ])
            return (
              <div style={{ background: `${colors.primary}08`, border: `1px solid ${colors.primary}22`, borderRadius: radius.md, padding: '14px 16px', marginBottom: '28px' }}>
                <div style={{ fontSize: '12px', fontWeight: 700, color: colors.primary, marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Your Workshop Plan
                </div>
                <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap', marginBottom: '8px' }}>
                  <span style={{ fontSize: '13px', color: '#333' }}>
                    <strong>{uniqueWorkshops.size}</strong> workshops total
                  </span>
                  <span style={{ fontSize: '13px', color: '#333' }}>
                    <strong>~{totalHours + 2}h</strong> estimated duration
                  </span>
                  <span style={{ fontSize: '13px', color: '#333' }}>
                    <strong>{foundationCount}</strong> foundation + <strong>{form.modules.length}</strong> selected bundle{form.modules.length !== 1 ? 's' : ''}
                  </span>
                </div>
                <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                  {form.modules.map((id) => (
                    <span key={id} style={{ background: colors.primary, color: '#fff', padding: '2px 10px', borderRadius: '12px', fontSize: '11px', fontWeight: 600 }}>
                      {bundles[id]?.title || id}
                    </span>
                  ))}
                </div>
              </div>
            )
          })()}

          {error && (
            <div style={{ background: '#FFEBEE', color: colors.error, padding: '10px 14px', borderRadius: radius.sm, fontSize: '14px', marginBottom: '16px' }}>
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            style={{ ...styles.btn.primary, width: '100%', padding: '14px', fontSize: '16px', opacity: loading ? 0.7 : 1 }}
          >
            {loading ? 'Registering…' : 'Register'}
          </button>
        </form>
      </div>
    </div>
  )
}
