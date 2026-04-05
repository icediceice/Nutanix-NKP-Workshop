import { useState, useEffect } from 'react'
import { colors, styles, radius } from '../styles/theme.js'

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
    await fetch(portalUrl, { method: 'HEAD', mode: 'no-cors', cache: 'no-store' })
    return true
  } catch {
    return false
  }
}

export default function SetupPage() {
  const [os, setOs] = useState('windows')
  const [certStatus, setCertStatus] = useState('checking')
  const [portalUrl, setPortalUrl] = useState('')

  useEffect(() => {
    setOs(detectOS())
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
      <div style={{ background: colors.elevated, border: `1px solid ${colors.border}`, borderRadius: radius.md, padding: '16px 20px', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <span style={{ fontSize: '20px' }}>&#8987;</span>
        <span style={{ color: colors.textSecondary, fontWeight: 600 }}>Checking certificate trust...</span>
      </div>
    )
    if (certStatus === 'trusted') return (
      <div style={{ background: colors.successBg, border: `1px solid ${colors.success}44`, borderLeft: `4px solid ${colors.success}`, borderRadius: radius.md, padding: '16px 20px', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <span style={{ fontSize: '24px', color: colors.success }}>&#10003;</span>
        <div>
          <div style={{ fontWeight: 700, color: colors.success }}>Certificate is trusted!</div>
          <div style={{ fontSize: '13px', color: colors.textSecondary, marginTop: '2px' }}>Your browser trusts the cluster CA. Workshop links will load correctly.</div>
        </div>
      </div>
    )
    return (
      <div style={{ background: colors.warningBg, border: `1px solid ${colors.warning}44`, borderLeft: `4px solid ${colors.warning}`, borderRadius: radius.md, padding: '16px 20px', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <span style={{ fontSize: '24px', color: colors.warning }}>&#9888;</span>
        <div>
          <div style={{ fontWeight: 700, color: colors.warning }}>Certificate not yet trusted</div>
          <div style={{ fontSize: '13px', color: colors.textSecondary, marginTop: '2px' }}>Follow the steps below, restart your browser, then click &ldquo;Check again&rdquo;.</div>
        </div>
      </div>
    )
  }

  return (
    <div style={{ maxWidth: '720px', margin: '0 auto' }}>
      <h2 style={{ fontSize: '22px', fontWeight: 700, color: colors.textPrimary, marginBottom: '8px' }}>
        One-Time Certificate Setup
      </h2>
      <p style={{ color: colors.textSecondary, fontSize: '14px', marginBottom: '24px', lineHeight: 1.6 }}>
        The workshop cluster uses a private CA certificate. You need to install it once so your browser trusts the lab URLs. This takes about 2 minutes.
      </p>

      {statusBox()}

      {/* OS Selector */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '24px' }}>
        {['windows', 'mac', 'linux'].map(o => (
          <button key={o} onClick={() => setOs(o)} style={{
            padding: '8px 20px',
            borderRadius: radius.sm,
            border: `2px solid ${os === o ? colors.accent : colors.border}`,
            background: os === o ? colors.accent : 'transparent',
            color: os === o ? '#fff' : colors.textSecondary,
            fontWeight: 600,
            fontSize: '13px',
            cursor: 'pointer',
            textTransform: 'capitalize',
          }}>
            {o === 'mac' ? 'macOS' : o.charAt(0).toUpperCase() + o.slice(1)}
          </button>
        ))}
      </div>

      {os === 'windows' && (
        <div style={{ ...styles.card, marginBottom: '16px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 700, color: colors.accent, marginBottom: '16px' }}>Windows — Recommended (one click)</h3>
          <ol style={{ paddingLeft: '20px', lineHeight: 2, color: colors.textSecondary, fontSize: '14px' }}>
            <li>Click <strong style={{ color: colors.textPrimary }}>Download Installer ZIP</strong> below and extract it</li>
            <li>Right-click <code style={codeStyle}>install-nkp-workshop-ca.bat</code> &rarr; <strong style={{ color: colors.textPrimary }}>Run as administrator</strong></li>
            <li>Click <strong style={{ color: colors.textPrimary }}>Yes</strong> on the UAC prompt</li>
            <li><strong style={{ color: colors.textPrimary }}>Restart your browser completely</strong> (close all windows)</li>
            <li>Click <strong style={{ color: colors.textPrimary }}>Check again</strong> below</li>
          </ol>
          <div style={{ display: 'flex', gap: '12px', marginTop: '20px', flexWrap: 'wrap' }}>
            <a href={`${API}/setup/install-cert.zip`} style={btnStyle(colors.accent)}>&#11123; Download Installer ZIP</a>
            <a href={`${API}/setup/ca.crt`} style={btnStyle(colors.elevated, colors.textSecondary, colors.border)}>&#11123; Download CA cert only (.crt)</a>
          </div>
        </div>
      )}

      {os === 'mac' && (
        <div style={{ ...styles.card, marginBottom: '16px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 700, color: colors.accent, marginBottom: '16px' }}>macOS</h3>
          <ol style={{ paddingLeft: '20px', lineHeight: 2, color: colors.textSecondary, fontSize: '14px' }}>
            <li>Click <strong style={{ color: colors.textPrimary }}>Download CA Certificate</strong> below</li>
            <li>The file opens in <strong style={{ color: colors.textPrimary }}>Keychain Access</strong> automatically — click <strong style={{ color: colors.textPrimary }}>Add</strong></li>
            <li>In Keychain Access, find <strong style={{ color: colors.textPrimary }}>kommander-ca</strong> under System or login keychain</li>
            <li>Double-click it &rarr; expand <strong style={{ color: colors.textPrimary }}>Trust</strong> &rarr; set <em>When using this certificate</em> to <strong style={{ color: colors.textPrimary }}>Always Trust</strong></li>
            <li>Enter your password and click <strong style={{ color: colors.textPrimary }}>Update Settings</strong></li>
            <li><strong style={{ color: colors.textPrimary }}>Restart your browser completely</strong></li>
            <li>Click <strong style={{ color: colors.textPrimary }}>Check again</strong> below</li>
          </ol>
          <div style={{ marginTop: '20px' }}>
            <a href={`${API}/setup/ca.crt`} style={btnStyle(colors.accent)}>&#11123; Download CA Certificate</a>
          </div>
        </div>
      )}

      {os === 'linux' && (
        <div style={{ ...styles.card, marginBottom: '16px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 700, color: colors.accent, marginBottom: '16px' }}>Linux</h3>
          <p style={{ fontSize: '14px', color: colors.textSecondary, marginBottom: '12px' }}>Download the cert, then run the commands for your system:</p>
          <div style={{ marginBottom: '20px' }}>
            <a href={`${API}/setup/ca.crt`} style={btnStyle(colors.accent)}>&#11123; Download CA Certificate</a>
          </div>
          <p style={{ fontSize: '13px', fontWeight: 700, color: colors.textPrimary, marginBottom: '6px' }}>Ubuntu / Debian:</p>
          <pre style={preStyle}>{`sudo cp ~/Downloads/nkp-workshop-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates`}</pre>
          <p style={{ fontSize: '13px', fontWeight: 700, color: colors.textPrimary, margin: '12px 0 6px' }}>Chrome / Chromium (all distros):</p>
          <pre style={preStyle}>{`# Settings → Privacy → Manage certificates → Authorities → Import`}</pre>
          <p style={{ fontSize: '13px', fontWeight: 700, color: colors.textPrimary, margin: '12px 0 6px' }}>Firefox:</p>
          <pre style={preStyle}>{`# Settings → Privacy → View Certificates → Authorities → Import`}</pre>
          <p style={{ fontSize: '13px', color: colors.textSecondary, marginTop: '12px' }}>After importing, restart your browser.</p>
        </div>
      )}

      <button onClick={recheck} style={{ ...btnStyle(certStatus === 'trusted' ? colors.success : colors.primary), marginBottom: '16px' }}>
        &#8635; Check again
      </button>

      {certStatus === 'trusted' && (
        <div style={{ fontSize: '14px', color: colors.textSecondary }}>
          You&rsquo;re all set! Go to the <a href="/status" style={{ color: colors.spark, fontWeight: 600 }}>status page</a> and open your workshops.
        </div>
      )}
    </div>
  )
}

const codeStyle = {
  background: colors.elevated,
  color: colors.spark,
  padding: '1px 6px',
  borderRadius: '3px',
  fontFamily: 'monospace',
  fontSize: '13px',
  border: `1px solid ${colors.border}`,
}

const preStyle = {
  background: '#0A0A0A',
  color: '#CDD6F4',
  padding: '12px 16px',
  borderRadius: radius.sm,
  fontSize: '12px',
  fontFamily: 'monospace',
  overflowX: 'auto',
  margin: 0,
  border: `1px solid ${colors.border}`,
}

function btnStyle(bg, color = '#fff', border) {
  return {
    display: 'inline-block',
    background: bg,
    color,
    border: border ? `1px solid ${border}` : 'none',
    padding: '10px 20px',
    borderRadius: radius.sm,
    fontWeight: 600,
    fontSize: '13px',
    textDecoration: 'none',
    cursor: 'pointer',
    fontFamily: 'inherit',
  }
}
