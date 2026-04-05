import { useState } from 'react'
import { colors, styles, radius } from '../styles/theme.js'

export default function QuizRenderer({ quiz }) {
  const [answers, setAnswers] = useState({})
  const [submitted, setSubmitted] = useState(false)

  if (!quiz) return null

  const score = submitted
    ? quiz.questions.filter((q) => answers[q.id] === q.correct).length
    : 0
  const pass = score >= quiz.questions.length * 0.7

  const handleSubmit = () => {
    if (Object.keys(answers).length < quiz.questions.length) {
      alert('Please answer all questions before submitting.')
      return
    }
    setSubmitted(true)
  }

  return (
    <div>
      <h2 style={{ color: colors.textPrimary, marginBottom: '4px' }}>{quiz.title}</h2>
      <p style={{ color: colors.textSecondary, fontSize: '14px', marginBottom: '24px' }}>
        {quiz.questions.length} questions
      </p>

      {submitted && (
        <div style={{
          background: pass ? colors.successBg : colors.warningBg,
          border: `1px solid ${pass ? colors.success : colors.warning}44`,
          borderLeft: `4px solid ${pass ? colors.success : colors.warning}`,
          borderRadius: radius.md,
          padding: '16px',
          marginBottom: '24px',
          textAlign: 'center',
        }}>
          <div style={{ fontSize: '32px', fontWeight: 700, color: pass ? colors.success : colors.warning }}>
            {score} / {quiz.questions.length}
          </div>
          <div style={{ fontSize: '14px', color: colors.textSecondary, marginTop: '4px' }}>
            {score === quiz.questions.length ? 'Perfect score!' : pass ? 'Good work!' : 'Review the explanations below and try again.'}
          </div>
        </div>
      )}

      {quiz.questions.map((q, qi) => {
        const correct = answers[q.id] === q.correct
        return (
          <div key={q.id} style={{
            marginBottom: '20px',
            padding: '20px',
            background: colors.surface,
            borderRadius: radius.md,
            border: submitted
              ? `2px solid ${correct ? colors.success + '88' : colors.error + '88'}`
              : `1px solid ${colors.border}`,
          }}>
            <div style={{ fontWeight: 600, fontSize: '15px', marginBottom: '12px', color: colors.textPrimary }}>
              <span style={{ color: colors.accent, marginRight: '8px' }}>{qi + 1}.</span>
              {q.question}
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {q.options.map((opt, oi) => {
                const isSelected = answers[q.id] === oi
                const isCorrect = oi === q.correct
                let bg = colors.elevated
                let border = `1px solid ${colors.border}`
                let textColor = colors.textSecondary
                if (submitted && isCorrect) { bg = colors.successBg; border = `1px solid ${colors.success}66`; textColor = colors.success }
                else if (submitted && isSelected && !isCorrect) { bg = colors.errorBg; border = `1px solid ${colors.error}66`; textColor = colors.error }
                else if (!submitted && isSelected) { bg = `${colors.accent}18`; border = `1px solid ${colors.accent}`; textColor = colors.textPrimary }

                return (
                  <button
                    key={oi}
                    type="button"
                    disabled={submitted}
                    onClick={() => !submitted && setAnswers((a) => ({ ...a, [q.id]: oi }))}
                    style={{ background: bg, border, borderRadius: radius.sm, padding: '10px 14px', textAlign: 'left', cursor: submitted ? 'default' : 'pointer', fontSize: '14px', color: textColor }}
                  >
                    <span style={{ fontWeight: 700, marginRight: '8px', color: colors.accent }}>{String.fromCharCode(65 + oi)}.</span>
                    {opt}
                  </button>
                )
              })}
            </div>
            {submitted && answers[q.id] !== q.correct && (
              <div style={{ marginTop: '12px', padding: '10px 14px', background: colors.warningBg, border: `1px solid ${colors.warning}33`, borderRadius: radius.sm, fontSize: '13px', color: colors.textSecondary }}>
                <strong style={{ color: colors.warning }}>Explanation: </strong>{q.explanation}
              </div>
            )}
          </div>
        )
      })}

      {!submitted ? (
        <button onClick={handleSubmit} style={{ ...styles.btn.primary, padding: '12px 32px' }}>
          Submit Answers
        </button>
      ) : (
        <button onClick={() => { setAnswers({}); setSubmitted(false) }} style={styles.btn.outline}>
          Retake Quiz
        </button>
      )}
    </div>
  )
}
