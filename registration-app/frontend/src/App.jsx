import { Routes, Route, Link, useLocation } from 'react-router-dom'
import RegistrationForm from './components/RegistrationForm.jsx'
import AdminPanel from './components/AdminPanel.jsx'
import StatusPage from './components/StatusPage.jsx'
import SetupPage from './components/SetupPage.jsx'
import { colors, styles } from './styles/theme.js'

function NutanixLogo() {
  return (
    <svg width="130" height="28" viewBox="0 0 130 28" fill="none" xmlns="http://www.w3.org/2000/svg" aria-label="Nutanix">
      {/* Stylised N mark */}
      <polyline points="2,24 2,4 13,20 13,4" stroke={colors.spark} strokeWidth="2.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      <line x1="13" y1="4" x2="22" y2="24" stroke={colors.accent} strokeWidth="2.5" strokeLinecap="round"/>
      {/* Wordmark */}
      <text x="30" y="20" fill={colors.textPrimary} fontFamily="Montserrat, sans-serif" fontSize="14" fontWeight="700" letterSpacing="2.5">NUTANIX</text>
    </svg>
  )
}

function Header() {
  const location = useLocation()
  const isAdmin = location.pathname.startsWith('/admin')
  const isStatus = location.pathname.startsWith('/status')
  const isSetup = location.pathname.startsWith('/setup')

  return (
    <header style={styles.header}>
      <Link to="/" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center' }}>
        <NutanixLogo />
      </Link>
      <div style={{ width: '1px', height: '24px', background: colors.border, margin: '0 8px' }} />
      <div style={{ fontSize: '13px', color: colors.textSecondary, fontWeight: 500, letterSpacing: '0.5px' }}>
        NKP Partner Workshop
      </div>
      <nav style={{ display: 'flex', gap: '20px', fontSize: '13px', alignItems: 'center', marginLeft: 'auto' }}>
        {isAdmin || isStatus || isSetup ? (
          <Link to="/" style={{ color: colors.spark, textDecoration: 'none', fontWeight: 600 }}>
            ← Registration
          </Link>
        ) : (
          <>
            <Link to="/setup" style={{ color: colors.textSecondary, textDecoration: 'none', fontWeight: 500 }}>
              &#128274; Cert Setup
            </Link>
            <Link to="/status" style={{ color: colors.textSecondary, textDecoration: 'none', fontWeight: 500 }}>
              Check My Status
            </Link>
            <Link to="/admin" style={{ color: colors.spark, textDecoration: 'none', fontWeight: 600 }}>
              Admin →
            </Link>
          </>
        )}
      </nav>
    </header>
  )
}

export default function App() {
  return (
    <div style={styles.page}>
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
