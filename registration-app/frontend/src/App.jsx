import { Routes, Route, Link, useLocation } from 'react-router-dom'
import RegistrationForm from './components/RegistrationForm.jsx'
import AdminPanel from './components/AdminPanel.jsx'
import StatusPage from './components/StatusPage.jsx'
import { colors, styles } from './styles/theme.js'

function Header() {
  const location = useLocation()
  const isAdmin = location.pathname.startsWith('/admin')
  const isStatus = location.pathname.startsWith('/status')

  return (
    <header style={styles.header}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: '11px', letterSpacing: '2px', opacity: 0.7, textTransform: 'uppercase' }}>
          Nutanix
        </div>
        <div style={{ fontSize: '20px', fontWeight: 700, marginTop: '2px' }}>
          NKP Partner Workshop
        </div>
      </div>
      <nav style={{ display: 'flex', gap: '20px', fontSize: '14px', alignItems: 'center' }}>
        {isAdmin || isStatus ? (
          <Link to="/" style={{ color: colors.spark, textDecoration: 'none', fontWeight: 600 }}>
            ← Registration
          </Link>
        ) : (
          <>
            <Link to="/status" style={{ color: 'rgba(255,255,255,0.75)', textDecoration: 'none', fontWeight: 500 }}>
              Check My Status
            </Link>
            <Link to="/admin" style={{ color: colors.spark, textDecoration: 'none', fontWeight: 600 }}>
              Admin Panel
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
          <Route path="/admin/*" element={<AdminPanel />} />
        </Routes>
      </main>
    </div>
  )
}
