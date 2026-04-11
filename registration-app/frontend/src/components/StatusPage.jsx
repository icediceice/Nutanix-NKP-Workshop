import { useState } from 'react'
import { getStatus } from '../api.js'
import { colors, styles, shadows, radius } from '../styles/theme.js'

function Spinner() {
  return (
    <span
      style={{
        display: 'inline-block',
        width: '18px',
        height: '18px',
        border: `3px solid ${colors.warningBg}`,
        borderTop: `3px solid ${colors.warning}`,
        borderRadius: '50%',
        animation: 'spin 0.9s linear infinite',
        verticalAlign: 'middle',
        marginRight: '10px',
      }}
    />
  )
}

function SpinnerStyle() {
  return (
    <style>{`
      @keyframes spin {
        to { transform: rotate(360deg); }
      }
      @keyframes pulse-border {
        0%, 100% { box-shadow: 0 0 0 0 rgba(251, 176, 64, 0.3); }
        50%       { box-shadow: 0 0 0 6px rgba(251, 176, 64, 0); }
      }
    `}</style>
  )
}

function StatusBanner({ status, errorMessage }) {
  if (status === 'registered') {
    return (
      <div style={{
        background: colors.infoBg,
        border: `1px solid ${colors.info}44`,
        borderLeft: `4px solid ${colors.info}`,
        borderRadius: radius.md,
        padding: '16px 20px',
        color: colors.info,
        fontSize: '15px',
        fontWeight: 500,
      }}>
        <div style={{ fontWeight: 700, marginBottom: '4px', fontSize: '16px' }}>Spot confirmed</div>
        Your spot is confirmed. The trainer will provision your environments soon.
      </div>
    )
  }

  if (status === 'provisioning') {
    return (
      <div style={{
        background: colors.warningBg,
        border: `1px solid ${colors.warning}44`,
        borderLeft: `4px solid ${colors.warning}`,
        borderRadius: radius.md,
        padding: '16px 20px',
        color: colors.warning,
        fontSize: '15px',
        fontWeight: 500,
        animation: 'pulse-border 2s ease-in-out infinite',
      }}>
        <div style={{ fontWeight: 700, marginBottom: '6px', fontSize: '16px', display: 'flex', alignItems: 'center' }}>
          <Spinner />
          Setting up your environments
        </div>
        Your environments are being set up&hellip; This usually takes a few minutes. Refresh
        this page to check again.
      </div>
    )
  }

  if (status === 'error') {
    return (
      <div style={{
        background: colors.errorBg,
        border: `1px solid ${colors.error}44`,
        borderLeft: `4px solid ${colors.error}`,
        borderRadius: radius.md,
        padding: '16px 20px',
        color: colors.error,
        fontSize: '15px',
        fontWeight: 500,
      }}>
        <div style={{ fontWeight: 700, marginBottom: '4px', fontSize: '16px' }}>Provisioning error</div>
        {errorMessage || 'An unexpected error occurred. Please contact your trainer.'}
      </div>
    )
  }

  return null
}

function extractSessionUrls(activationUrl) {
  try {
    const u = new URL(activationUrl)
    const match = u.pathname.match(/\/workshops\/session\/([^/]+)\//)
    if (!match) return null
    const sessionName = match[1]
    const hostParts = u.hostname.split('.')
    const baseDomain = hostParts.slice(1).join('.')
    return {
      session: `${u.protocol}//${sessionName}.${baseDomain}`,
      console: `${u.protocol}//console-${sessionName}.${baseDomain}`,
    }
  } catch {
    return null
  }
}

// Derive the Educates portal account-creation URL from any workshop activation URL.
// Participants visit this once per browser session to create their anonymous portal
// account; after that, all activation links work without showing the login wall.
function portalAccountUrl(activationUrl) {
  try {
    const u = new URL(activationUrl)
    return `${u.protocol}//${u.hostname}/accounts/create/`
  } catch {
    return null
  }
}

function WorkshopUrlCard({ name, url }) {
  const displayName = name
    .replace(/-/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase())

  const sessionUrls = extractSessionUrls(url)
  const contentUrl = `https://light.factor-io.com/workshop/${name}/`

  return (
    <div style={{
      ...styles.card,
      borderTop: `3px solid ${colors.accent}`,
      boxShadow: shadows.elevated,
      display: 'flex',
      flexDirection: 'column',
      gap: '12px',
    }}>
      <div style={{ fontSize: '13px', color: colors.textSecondary, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
        Workshop
      </div>
      <div style={{ fontWeight: 700, fontSize: '17px', color: colors.textPrimary }}>
        {displayName}
      </div>

      {sessionUrls && (
        <div style={{ background: colors.warningBg, border: `1px solid ${colors.warning}33`, borderRadius: radius.sm, padding: '10px 12px', fontSize: '13px' }}>
          <div style={{ fontWeight: 700, color: colors.warning, marginBottom: '6px' }}>Terminal setup (one time):</div>
          <div style={{ color: colors.textSecondary, marginBottom: '8px', lineHeight: 1.5 }}>
            Click <strong style={{ color: colors.textPrimary }}>Terminal</strong> below &rarr; accept the cert warning once &rarr; keep that tab open.
          </div>
          <a href={sessionUrls.session} target="_blank" rel="noopener noreferrer"
            style={{ display: 'inline-block', background: colors.warning, color: '#000', padding: '6px 12px', borderRadius: radius.sm, fontWeight: 600, fontSize: '12px', textDecoration: 'none' }}>
            &#9654; Terminal
          </a>
        </div>
      )}

      <a href={contentUrl} target="_blank" rel="noopener noreferrer"
        style={{ ...styles.btn.primary, background: colors.accent, display: 'inline-block', textAlign: 'center', textDecoration: 'none', marginTop: 'auto', padding: '11px 20px', fontSize: '14px' }}>
        Workshop Content &rarr;
      </a>
    </div>
  )
}

function ReadySection({ data }) {
  const urls = data.workshop_urls || {}
  const urlEntries = Object.entries(urls)
  const modules = Array.isArray(data.modules) ? data.modules : []
  const accountUrl = urlEntries.length > 0 ? portalAccountUrl(urlEntries[0][1]) : null

  return (
    <div>
      <div style={{
        background: colors.successBg,
        border: `1px solid ${colors.success}44`,
        borderLeft: `4px solid ${colors.success}`,
        borderRadius: radius.md,
        padding: '16px 20px',
        marginBottom: '16px',
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
      }}>
        <span style={{ fontSize: '26px', lineHeight: 1, color: colors.success }}>&#10003;</span>
        <div>
          <div style={{ fontWeight: 700, fontSize: '16px', color: colors.success }}>Your environments are ready!</div>
          <div style={{ fontSize: '14px', color: colors.textSecondary, marginTop: '2px' }}>Follow the steps below to access your workshops.</div>
        </div>
      </div>

      {accountUrl && (
        <div style={{
          background: colors.elevated,
          border: `1px solid ${colors.accent}44`,
          borderLeft: `4px solid ${colors.accent}`,
          borderRadius: radius.md,
          padding: '14px 16px',
          marginBottom: '20px',
          display: 'flex',
          alignItems: 'center',
          gap: '16px',
          flexWrap: 'wrap',
        }}>
          <div style={{ flex: 1, minWidth: '200px' }}>
            <div style={{ fontWeight: 700, fontSize: '14px', color: colors.textPrimary, marginBottom: '2px' }}>
              Step 1: Create your workshop account <span style={{ fontWeight: 400, color: colors.textSecondary }}>(one time per browser)</span>
            </div>
            <div style={{ fontSize: '13px', color: colors.textSecondary }}>
              This sets up anonymous access to the portal. After this, workshop links open directly.
            </div>
          </div>
          <a href={accountUrl} target="_blank" rel="noopener noreferrer"
            style={{ background: colors.accent, color: '#fff', padding: '8px 16px', borderRadius: radius.sm, fontWeight: 600, fontSize: '13px', textDecoration: 'none', whiteSpace: 'nowrap' }}>
            Create Account &rarr;
          </a>
        </div>
      )}

      {modules.length > 0 && (
        <div style={{ marginBottom: '20px' }}>
          <div style={{ fontSize: '12px', fontWeight: 700, color: colors.textSecondary, textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '8px' }}>
            Enrolled modules
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
            {modules.map((mod) => (
              <span key={mod} style={{ background: colors.elevated, color: colors.accent, border: `1px solid ${colors.accent}44`, padding: '3px 10px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 }}>
                {mod}
              </span>
            ))}
          </div>
        </div>
      )}

      {urlEntries.length > 0 ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: '16px' }}>
          {urlEntries.map(([name, url]) => (
            <WorkshopUrlCard key={name} name={name} url={url} />
          ))}
        </div>
      ) : (
        <div style={{ color: colors.textSecondary, fontSize: '14px' }}>
          No workshop URLs are available yet. Check back shortly.
        </div>
      )}
    </div>
  )
}

export default function StatusPage() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState(null)
  const [inputError, setInputError] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    const trimmed = email.trim()
    if (!trimmed) { setInputError('Please enter your email address.'); return }
    setInputError('')
    setLoading(true)
    setResult(null)
    try {
      const response = await getStatus(trimmed)
      setResult({ status: response.data.status, data: response.data, notFound: false })
    } catch (err) {
      if (err.response?.status === 404) {
        setResult({ status: null, data: null, notFound: true })
      } else {
        setResult({
          status: 'error',
          data: { error_message: err.response?.data?.detail || err.response?.data?.error_message || 'Unable to reach the server. Please try again.' },
          notFound: false,
        })
      }
    } finally {
      setLoading(false)
    }
  }

  const handleReset = () => { setResult(null); setEmail(''); setInputError('') }

  return (
    <>
      <SpinnerStyle />
      <div style={{ maxWidth: '720px', margin: '0 auto' }}>

        {!result && (
          <div style={{ ...styles.card, boxShadow: shadows.elevated }}>
            <h1 style={{ color: colors.textPrimary, fontSize: '22px', marginBottom: '4px' }}>
              Check your workshop status
            </h1>
            <p style={{ color: colors.textSecondary, fontSize: '14px', marginBottom: '28px' }}>
              Enter the email address you used to register.
            </p>
            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom: '12px' }}>
                <label htmlFor="status-email" style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px', color: colors.textSecondary }}>
                  Email address <span style={{ color: colors.error }}>*</span>
                </label>
                <input
                  id="status-email"
                  type="email"
                  placeholder="you@company.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={loading}
                  autoFocus
                  style={{ ...styles.input, borderColor: inputError ? colors.error : undefined }}
                />
                {inputError && <div style={{ color: colors.error, fontSize: '12px', marginTop: '4px' }}>{inputError}</div>}
              </div>
              <button type="submit" disabled={loading} style={{ ...styles.btn.primary, width: '100%', padding: '13px', fontSize: '15px', opacity: loading ? 0.7 : 1, marginTop: '8px' }}>
                {loading ? 'Checking\u2026' : 'Check Status'}
              </button>
            </form>
          </div>
        )}

        {result && (
          <div style={{ ...styles.card, boxShadow: shadows.elevated }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '20px', gap: '12px' }}>
              <div>
                <div style={{ fontSize: '13px', color: colors.textSecondary, fontWeight: 600, marginBottom: '2px' }}>Status for</div>
                <div style={{ fontWeight: 700, color: colors.accent, fontSize: '16px', wordBreak: 'break-all' }}>{email}</div>
              </div>
              <button onClick={handleReset} style={{ ...styles.btn.outline, whiteSpace: 'nowrap', flexShrink: 0 }}>
                Check another email
              </button>
            </div>

            {result.notFound && (
              <div style={{ background: colors.warningBg, border: `1px solid ${colors.warning}44`, borderLeft: `4px solid ${colors.warning}`, borderRadius: radius.md, padding: '16px 20px', color: colors.warning, fontSize: '14px' }}>
                <div style={{ fontWeight: 700, marginBottom: '4px', fontSize: '15px' }}>Email not found</div>
                Email not found in the active session. Check with your trainer.
              </div>
            )}

            {!result.notFound && result.status !== 'ready' && (
              <StatusBanner status={result.status} errorMessage={result.data?.error_message} />
            )}

            {!result.notFound && result.status === 'ready' && (
              <ReadySection data={result.data} />
            )}
          </div>
        )}

      </div>
    </>
  )
}
