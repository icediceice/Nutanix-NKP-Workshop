import { useState } from 'react'
import { register } from '../api.js'
import ModuleSelector from './ModuleSelector.jsx'
import { colors, styles, shadows, radius } from '../styles/theme.js'

export default function RegistrationForm() {
  const [form, setForm] = useState({ name: '', email: '', company: '', modules: [] })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(null)

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

          <div style={{ marginBottom: '28px' }}>
            <ModuleSelector
              value={form.modules}
              onChange={(modules) => setForm((f) => ({ ...f, modules }))}
            />
          </div>

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
