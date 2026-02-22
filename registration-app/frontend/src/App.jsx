import { Routes, Route, Link, useLocation } from 'react-router-dom'
import RegistrationForm from './components/RegistrationForm.jsx'
import AdminPanel from './components/AdminPanel.jsx'
import { colors, styles } from './styles/theme.js'

function Header() {
  const location = useLocation()
  const isAdmin = location.pathname.startsWith('/admin')

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
      <nav style={{ display: 'flex', gap: '16px', fontSize: '14px' }}>
        {isAdmin ? (
          <Link to="/" style={{ color: colors.spark, textDecoration: 'none', fontWeight: 600 }}>
            ← Registration
          </Link>
        ) : (
          <Link to="/admin" style={{ color: colors.spark, textDecoration: 'none', fontWeight: 600 }}>
            Admin Panel
          </Link>
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
          <Route path="/admin/*" element={<AdminPanel />} />
        </Routes>
      </main>
    </div>
  )
}
