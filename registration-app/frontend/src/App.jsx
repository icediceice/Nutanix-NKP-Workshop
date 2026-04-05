import { Routes, Route, Link, useLocation } from 'react-router-dom'
import RegistrationForm from './components/RegistrationForm.jsx'
import AdminPanel from './components/AdminPanel.jsx'
import StatusPage from './components/StatusPage.jsx'
import SetupPage from './components/SetupPage.jsx'
import { colors, styles, gradient } from './styles/theme.js'

function NutanixLogo() {
  return (
    <svg width="130" height="26" viewBox="0 0 130 26" fill="none" xmlns="http://www.w3.org/2000/svg" aria-label="Nutanix">
      {/* Stylised N mark — teal downstroke, violet diagonal */}
      <polyline points="2,22 2,4 13,18 13,4" stroke={colors.spark} strokeWidth="2.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      <line x1="13" y1="4" x2="22" y2="22" stroke={colors.accent} strokeWidth="2.5" strokeLinecap="round"/>
      {/* Wordmark */}
      <text x="29" y="19" fill={colors.textPrimary} fontFamily="Montserrat, sans-serif" fontSize="13" fontWeight="700" letterSpacing="2.5">NUTANIX</text>
    </svg>
  )
}

function Header() {
  const location = useLocation()
  const isAdmin = location.pathname.startsWith('/admin')
  const isStatus = location.pathname.startsWith('/status')
  const isSetup = location.pathname.startsWith('/setup')

  return (
    <header>
      {/* Gradient accent line at top */}
      <div style={{ height: '2px', background: gradient, position: 'absolute', top: 0, left: 0, right: 0 }} />
      <div style={{ ...styles.header, paddingTop: '16px' }}>
        <Link to="/" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center' }}>
          <NutanixLogo />
        </Link>
        <div style={{ width: '1px', height: '20px', background: colors.border, margin: '0 4px' }} />
        <div style={{ fontSize: '12px', color: colors.textMuted, fontWeight: 600, letterSpacing: '1px', textTransform: 'uppercase' }}>
          NKP Partner Workshop
        </div>
        <nav style={{ display: 'flex', gap: '4px', fontSize: '13px', alignItems: 'center', marginLeft: 'auto' }}>
          {isAdmin || isStatus || isSetup ? (
            <NavLink to="/">← Registration</NavLink>
          ) : (
            <>
              <NavLink to="/setup">🔒 Cert Setup</NavLink>
              <NavLink to="/status">Status</NavLink>
              <NavLink to="/admin" highlight>Admin →</NavLink>
            </>
          )}
        </nav>
      </div>
    </header>
  )
}

function NavLink({ to, children, highlight }) {
  const location = useLocation()
  const active = location.pathname.startsWith(to === '/' ? '/__never__' : to)
  return (
    <Link
      to={to}
      style={{
        padding: '6px 12px',
        borderRadius: '4px',
        textDecoration: 'none',
        fontWeight: 600,
        color: highlight ? colors.spark : active ? colors.textPrimary : colors.textSecondary,
        background: active ? colors.elevated : 'transparent',
        transition: 'all 0.15s',
      }}
    >
      {children}
    </Link>
  )
}

export default function App() {
  return (
    <div style={{ ...styles.page, position: 'relative' }}>
      <Header />
      <main style={{ padding: '32px', maxWidth: '1100px', margin: '0 auto' }}>
        <Routes>
          <Route path="/" element={<RegistrationForm />} />
          <Route path="/status" element={<StatusPage />} />
          <Route path="/setup" element={<SetupPage />} />
          <Route path="/admin/*" element={<AdminPanel />} />
        </Routes>
      </main>
    </div>
  )
}
