// Nutanix brand theme
export const colors = {
  primary: '#4B00AA',      // Deep purple
  accent: '#7855FA',       // Violet
  spark: '#1FDDE9',        // Teal
  dark: '#131313',
  white: '#FFFFFF',
  lightGray: '#F5F5F5',
  midGray: '#E0E0E0',
  textGray: '#555555',
  error: '#D32F2F',
  success: '#2E7D32',
  warning: '#F57C00',
}

export const fonts = {
  family: "'Montserrat', sans-serif",
}

export const shadows = {
  card: '0 2px 8px rgba(0,0,0,0.10)',
  elevated: '0 4px 16px rgba(75,0,170,0.15)',
}

export const radius = {
  sm: '4px',
  md: '8px',
  lg: '12px',
}

// Reusable style objects
export const styles = {
  page: {
    minHeight: '100vh',
    background: colors.lightGray,
    fontFamily: fonts.family,
  },
  header: {
    background: colors.primary,
    color: colors.white,
    padding: '20px 32px',
    display: 'flex',
    alignItems: 'center',
    gap: '16px',
  },
  card: {
    background: colors.white,
    borderRadius: radius.md,
    boxShadow: shadows.card,
    padding: '24px',
  },
  btn: {
    primary: {
      background: colors.primary,
      color: colors.white,
      border: 'none',
      borderRadius: radius.sm,
      padding: '10px 20px',
      fontFamily: fonts.family,
      fontWeight: 600,
      fontSize: '14px',
      cursor: 'pointer',
    },
    accent: {
      background: colors.accent,
      color: colors.white,
      border: 'none',
      borderRadius: radius.sm,
      padding: '10px 20px',
      fontFamily: fonts.family,
      fontWeight: 600,
      fontSize: '14px',
      cursor: 'pointer',
    },
    outline: {
      background: 'transparent',
      color: colors.primary,
      border: `2px solid ${colors.primary}`,
      borderRadius: radius.sm,
      padding: '8px 18px',
      fontFamily: fonts.family,
      fontWeight: 600,
      fontSize: '14px',
      cursor: 'pointer',
    },
  },
  input: {
    width: '100%',
    padding: '10px 14px',
    border: `1px solid ${colors.midGray}`,
    borderRadius: radius.sm,
    fontFamily: fonts.family,
    fontSize: '14px',
    outline: 'none',
  },
  badge: {
    registered: { background: '#E3F2FD', color: '#1565C0', padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
    provisioning: { background: '#FFF8E1', color: '#F57C00', padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
    ready: { background: '#E8F5E9', color: '#2E7D32', padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
    error: { background: '#FFEBEE', color: '#C62828', padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
  },
}
