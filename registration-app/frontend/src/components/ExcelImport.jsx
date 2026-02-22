import { useState, useRef } from 'react'
import { importExcel, getImportTemplate } from '../api.js'
import { colors, styles, radius } from '../styles/theme.js'

export default function ExcelImport({ onImported }) {
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState(null)
  const fileRef = useRef(null)

  const handleImport = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    setLoading(true)
    setResult(null)
    try {
      const formData = new FormData()
      formData.append('file', file)
      const { data } = await importExcel(formData)
      setResult(data)
      onImported?.()
    } catch (err) {
      setResult({ error: err.response?.data?.detail || 'Import failed.' })
    } finally {
      setLoading(false)
      fileRef.current.value = ''
    }
  }

  const handleTemplate = async () => {
    const { data } = await getImportTemplate()
    const url = URL.createObjectURL(new Blob([data]))
    const a = document.createElement('a')
    a.href = url
    a.download = 'participant-template.xlsx'
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div style={{ display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap' }}>
      <input ref={fileRef} type="file" accept=".xlsx" style={{ display: 'none' }} onChange={handleImport} />
      <button onClick={() => fileRef.current.click()} disabled={loading} style={styles.btn.outline}>
        {loading ? 'Importing…' : '↑ Import Excel'}
      </button>
      <button onClick={handleTemplate} style={{ ...styles.btn.outline, fontSize: '12px' }}>
        ↓ Template
      </button>

      {result && !result.error && (
        <span style={{ fontSize: '13px', color: '#2E7D32', background: '#E8F5E9', padding: '6px 12px', borderRadius: radius.sm }}>
          Imported {result.imported} • Skipped {result.skipped}
          {result.errors?.length > 0 && ` • ${result.errors.length} error(s)`}
        </span>
      )}
      {result?.error && (
        <span style={{ fontSize: '13px', color: '#C62828', background: '#FFEBEE', padding: '6px 12px', borderRadius: radius.sm }}>
          {result.error}
        </span>
      )}
    </div>
  )
}
