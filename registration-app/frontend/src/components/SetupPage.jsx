import { useState, useEffect } from 'react'
import { colors, styles, radius, shadows } from '../styles/theme.js'

const API = import.meta.env.VITE_API_URL || ''

function detectOS() {
  const ua = navigator.userAgent || ''
  const platform = navigator.platform || ''
  if (/Win/i.test(platform) || /Windows/i.test(ua)) return 'windows'
  if (/Mac/i.test(platform) || /Macintosh/i.test(ua)) return 'mac'
  return 'linux'
}

async function checkCertTrusted(portalUrl) {
  if (!portalUrl) return null
  try {
    const resp = await fetch(portalUrl, { method: 'HEAD', mode: 'no-cors', cache: 'no-store' })
    // no-cors always returns opaque — if we get here without a TypeError, cert is trusted
    return true
  } catch {
    return false
  }
}

export default function SetupPage() {
  const [os, setOs] = useState('windows')
  const [certStatus, setCertStatus] = useState('checking') // checking | trusted | untrusted
  const [portalUrl, setPortalUrl] = useState('')

  useEffect(() => {
    setOs(detectOS())

    // Fetch config to learn portal URL, then check cert trust
    fetch(`${API}/setup/config`)
      .then(r => r.json())
      .then(async cfg => {
        const url = cfg.verify_url || cfg.portal_url || ''
        setPortalUrl(url)
        if (!url) { setCertStatus('untrusted'); return }
        const trusted = await checkCertTrusted(url)
        setCertStatus(trusted ? 'trusted' : 'untrusted')
      })
      .catch(() => setCertStatus('untrusted'))
  }, [])

  const recheck = async () => {
    setCertStatus('checking')
    const trusted = await checkCertTrusted(portalUrl)
    setCertStatus(trusted ? 'trusted' : 'untrusted')
  }

  const statusBox = () => {
    if (certStatus === 'checking') return (
      <div style={{ background: '#F3F4F6', border: '1px solid #D1D5DB', borderRadius: radius.md, padding: '16px 20px', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <span style={{ fontSize: '20px' }}>&#8987;</span>
        <span style={{ color: '#374151', fontWeight: 600 }}>Checking certificate trust...</span>
      </div>
    )
    if (certStatus === 'trusted') return (
      <div style={{ background: '#D1FAE5', border: '1px solid #6EE7B7', borderLeft: `4px solid ${colors.success}`, borderRadius: radius.md, padding: '16px 20px', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <span style={{ fontSize: '24px' }}>&#10003;</span>
        <div>
          <div style={{ fontWeight: 700, color: '#065F46' }}>Certificate is trusted!</div>
          <div style={{ fontSize: '13px', color: '#047857', marginTop: '2px' }}>Your browser trusts the cluster CA. Workshop links will load correctly.</div>
        </div>
      </div>
    )
    return (
      <div style={{ background: '#FEF3C7', border: '1px solid #FCD34D', borderLeft: '4px solid #F59E0B', borderRadius: radius.md, padding: '16px 20px', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <span style={{ fontSize: '24px' }}>&#9888;</span>
        <div>
          <div style={{ fontWeight: 700, color: '#92400E' }}>Certificate not yet trusted</div>
          <div style={{ fontSize: '13px', color: '#B45309', marginTop: '2px' }}>Follow the steps below, restart your browser, then click &ldquo;Check again&rdquo;.</div>
        </div>
      </div>
    )
  }

  return (
    <div style={{ maxWidth: '720px', margin: '0 auto' }}>
      <h2 style={{ fontSize: '22px', fontWeight: 700, color: colors.primary, marginBottom: '8px' }}>
        One-Time Certificate Setup
      </h2>
      <p style={{ color: colors.textGray, fontSize: '14px', marginBottom: '24px', lineHeight: 1.6 }}>
        The workshop cluster uses a private CA certificate. You need to install it once so your browser trusts the lab URLs. This takes about 2 minutes.
      </p>

      {statusBox()}

      {/* OS Selector */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '24px' }}>
        {['windows', 'mac', 'linux'].map(o => (
          <button
            key={o}
            onClick={() => setOs(o)}
            style={{
              padding: '8px 20px',
              borderRadius: radius.sm,
              border: `2px solid ${os === o ? colors.accent : colors.midGray}`,
              background: os === o ? colors.accent : 'transparent',
              color: os === o ? '#fff' : colors.textGray,
              fontWeight: 600,
              fontSize: '13px',
              cursor: 'pointer',
              textTransform: 'capitalize',
            }}
          >
            {o === 'mac' ? 'macOS' : o.charAt(0).toUpperCase() + o.slice(1)}
          </button>
        ))}
      </div>

      {/* Windows instructions */}
      {os === 'windows' && (
        <div style={{ ...styles.card, border: `1px solid ${colors.midGray}`, marginBottom: '16px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 700, color: colors.primary, marginBottom: '16px' }}>Windows — Recommended (one click)</h3>
          <ol style={{ paddingLeft: '20px', lineHeight: 2, color: colors.text, fontSize: '14px' }}>
            <li>Click <strong>Download Installer ZIP</strong> below and extract it</li>
            <li>Right-click <code style={codeStyle}>install-nkp-workshop-ca.bat</code> &rarr; <strong>Run as administrator</strong></li>
            <li>Click <strong>Yes</strong> on the UAC prompt</li>
            <li><strong>Restart your browser completely</strong> (close all windows)</li>
            <li>Click <strong>Check again</strong> below</li>
          </ol>
          <div style={{ display: 'flex', gap: '12px', marginTop: '20px', flexWrap: 'wrap' }}>
            <a href={`${API}/setup/install-cert.zip`} style={btnStyle(colors.accent)}>
              &#11123; Download Installer ZIP
            </a>
            <a href={`${API}/setup/ca.crt`} style={btnStyle('#6B7280')}>
              &#11123; Download CA cert only (.crt)
            </a>
          </div>
        </div>
      )}

      {/* macOS instructions */}
      {os === 'mac' && (
        <div style={{ ...styles.card, border: `1px solid ${colors.midGray}`, marginBottom: '16px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 700, color: colors.primary, marginBottom: '16px' }}>macOS</h3>
          <ol style={{ paddingLeft: '20px', lineHeight: 2, color: colors.text, fontSize: '14px' }}>
            <li>Click <strong>Download CA Certificate</strong> below</li>
            <li>The file opens in <strong>Keychain Access</strong> automatically — click <strong>Add</strong></li>
            <li>In Keychain Access, find <strong>kommander-ca</strong> under System or login keychain</li>
            <li>Double-click it &rarr; expand <strong>Trust</strong> &rarr; set <em>When using this certificate</em> to <strong>Always Trust</strong></li>
            <li>Enter your password and click <strong>Update Settings</strong></li>
            <li><strong>Restart your browser completely</strong></li>
            <li>Click <strong>Check again</strong> below</li>
          </ol>
          <div style={{ marginTop: '20px' }}>
            <a href={`${API}/setup/ca.crt`} style={btnStyle(colors.accent)}>
              &#11123; Download CA Certificate
            </a>
          </div>
        </div>
      )}

      {/* Linux instructions */}
      {os === 'linux' && (
        <div style={{ ...styles.card, border: `1px solid ${colors.midGray}`, marginBottom: '16px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 700, color: colors.primary, marginBottom: '16px' }}>Linux</h3>
          <p style={{ fontSize: '14px', color: colors.textGray, marginBottom: '12px' }}>Download the cert, then run the commands for your system:</p>
          <div style={{ marginBottom: '20px' }}>
            <a href={`${API}/setup/ca.crt`} style={btnStyle(colors.accent)}>
              &#11123; Download CA Certificate
            </a>
          </div>
          <p style={{ fontSize: '13px', fontWeight: 700, color: colors.text, marginBottom: '6px' }}>Ubuntu / Debian:</p>
          <pre style={preStyle}>{`sudo cp ~/Downloads/nkp-workshop-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates`}</pre>
          <p style={{ fontSize: '13px', fontWeight: 700, color: colors.text, margin: '12px 0 6px' }}>Chrome / Chromium (all distros):</p>
          <pre style={preStyle}>{`# Settings → Privacy → Manage certificates → Authorities → Import`}</pre>
          <p style={{ fontSize: '13px', fontWeight: 700, color: colors.text, margin: '12px 0 6px' }}>Firefox:</p>
          <pre style={preStyle}>{`# Settings → Privacy → View Certificates → Authorities → Import`}</pre>
          <p style={{ fontSize: '13px', color: colors.textGray, marginTop: '12px' }}>After importing, restart your browser.</p>
        </div>
      )}

      {/* Check again button */}
      <button
        onClick={recheck}
        style={{ ...btnStyle(certStatus === 'trusted' ? colors.success : colors.primary), marginBottom: '16px' }}
      >
        &#8635; Check again
      </button>

      {certStatus === 'trusted' && (
        <div style={{ fontSize: '14px', color: colors.textGray }}>
          You&rsquo;re all set! Go to the <a href="/status" style={{ color: colors.accent, fontWeight: 600 }}>status page</a> and open your workshops.
        </div>
      )}
    </div>
  )
}

const codeStyle = {
  background: '#F3F4F6',
  padding: '1px 6px',
  borderRadius: '3px',
  fontFamily: 'monospace',
  fontSize: '13px',
}

const preStyle = {
  background: '#1E1E2E',
  color: '#CDD6F4',
  padding: '12px 16px',
  borderRadius: radius.sm,
  fontSize: '12px',
  fontFamily: 'monospace',
  overflowX: 'auto',
  margin: 0,
}

function btnStyle(bg) {
  return {
    display: 'inline-block',
    background: bg,
    color: '#fff',
    padding: '10px 20px',
    borderRadius: radius.sm,
    fontWeight: 600,
    fontSize: '14px',
    textDecoration: 'none',
    border: 'none',
    cursor: 'pointer',
  }
}
