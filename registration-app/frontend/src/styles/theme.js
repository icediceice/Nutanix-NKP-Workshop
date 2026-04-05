// Nutanix brand theme — dark mode
export const colors = {
  primary: '#4B00AA',      // Deep purple
  accent: '#7855FA',       // Violet
  spark: '#1FDDE9',        // Teal
  dark: '#131313',
  white: '#FFFFFF',

  // Dark mode palette
  bg: '#0D0D0D',           // Page background
  surface: '#161616',      // Card / panel background
  elevated: '#1E1E1E',     // Elevated surfaces (modals, dropdowns)
  border: '#2A2A2A',       // Subtle borders
  borderStrong: '#3A3A3A', // Visible borders
  textPrimary: '#F0F0F0',  // Main text
  textSecondary: '#9A9A9A',// Secondary text
  textMuted: '#555555',    // Placeholder / muted

  // Semantic (dark-adjusted)
  error: '#F87171',
  errorBg: '#2D0A0A',
  success: '#4ADE80',
  successBg: '#0A2818',
  warning: '#FBB040',
  warningBg: '#2D1800',
  info: '#60A5FA',
  infoBg: '#0D2847',
}

export const fonts = {
  family: "'Montserrat', sans-serif",
}

export const shadows = {
  card: '0 2px 8px rgba(0,0,0,0.5)',
  elevated: '0 4px 20px rgba(0,0,0,0.7)',
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
    background: colors.bg,
    fontFamily: fonts.family,
    color: colors.textPrimary,
  },
  header: {
    background: '#0A0A0A',
    borderBottom: `1px solid ${colors.border}`,
    color: colors.textPrimary,
    padding: '16px 32px',
    display: 'flex',
    alignItems: 'center',
    gap: '16px',
  },
  card: {
    background: colors.surface,
    borderRadius: radius.md,
    border: `1px solid ${colors.border}`,
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
      color: colors.textSecondary,
      border: `1px solid ${colors.borderStrong}`,
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
    background: colors.elevated,
    border: `1px solid ${colors.borderStrong}`,
    borderRadius: radius.sm,
    fontFamily: fonts.family,
    fontSize: '14px',
    outline: 'none',
    color: colors.textPrimary,
  },
  badge: {
    registered: { background: colors.infoBg, color: colors.info, padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
    provisioning: { background: colors.warningBg, color: colors.warning, padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
    ready: { background: colors.successBg, color: colors.success, padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
    error: { background: colors.errorBg, color: colors.error, padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
  },
}
