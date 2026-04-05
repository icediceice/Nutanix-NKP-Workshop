// Nutanix brand theme — dark mode
export const colors = {
  // Brand
  primary:  '#4B00AA',      // Deep purple
  accent:   '#7855FA',      // Violet
  spark:    '#1FDDE9',      // Teal

  // Dark surfaces
  bg:            '#0D0D0D',  // Page background
  surface:       '#161616',  // Card / panel
  elevated:      '#1E1E1E',  // Elevated surfaces, inputs
  hover:         '#242424',  // Row / item hover
  border:        '#2A2A2A',  // Subtle border
  borderStrong:  '#3A3A3A',  // Visible border

  // Text
  textPrimary:   '#F0F0F0',
  textSecondary: '#888888',
  textMuted:     '#444444',

  // Semantic
  error:      '#F87171',
  errorBg:    '#2D0A0A',
  success:    '#34D399',
  successBg:  '#0A2818',
  warning:    '#FBB040',
  warningBg:  '#2D1800',
  info:       '#60A5FA',
  infoBg:     '#0D2240',

  // Nutanix gradient
  gradientStart: '#4B00AA',
  gradientEnd:   '#1FDDE9',
}

export const gradient = `linear-gradient(135deg, ${colors.gradientStart}, ${colors.gradientEnd})`
export const gradientSubtle = `linear-gradient(135deg, ${colors.gradientStart}22, ${colors.gradientEnd}22)`

export const fonts = {
  family: "'Montserrat', sans-serif",
}

export const shadows = {
  card:     '0 1px 3px rgba(0,0,0,0.6)',
  elevated: '0 4px 24px rgba(0,0,0,0.8)',
  glow:     `0 0 20px rgba(120,85,250,0.15)`,
}

export const radius = {
  sm: '4px',
  md: '8px',
  lg: '12px',
}

export const styles = {
  page: {
    minHeight: '100vh',
    background: colors.bg,
    fontFamily: fonts.family,
    color: colors.textPrimary,
  },
  header: {
    background: '#0D0D0D',
    borderBottom: `1px solid ${colors.border}`,
    color: colors.textPrimary,
    padding: '14px 32px',
    display: 'flex',
    alignItems: 'center',
    gap: '16px',
    position: 'sticky',
    top: 0,
    zIndex: 100,
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
      background: gradient,
      color: '#fff',
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
      color: '#fff',
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
    registered:  { background: colors.infoBg,    color: colors.info,    padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
    provisioning:{ background: colors.warningBg, color: colors.warning, padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
    ready:       { background: colors.successBg, color: colors.success, padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
    error:       { background: colors.errorBg,   color: colors.error,   padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600 },
  },
}
