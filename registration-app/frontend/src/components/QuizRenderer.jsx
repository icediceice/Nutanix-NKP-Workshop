import { useState } from 'react'
import { colors, styles, radius } from '../styles/theme.js'

export default function QuizRenderer({ quiz }) {
  const [answers, setAnswers] = useState({})
  const [submitted, setSubmitted] = useState(false)

  if (!quiz) return null

  const score = submitted
    ? quiz.questions.filter((q) => answers[q.id] === q.correct).length
    : 0

  const handleSubmit = () => {
    if (Object.keys(answers).length < quiz.questions.length) {
      alert('Please answer all questions before submitting.')
      return
    }
    setSubmitted(true)
  }

  return (
    <div>
      <h2 style={{ color: colors.primary, marginBottom: '4px' }}>{quiz.title}</h2>
      <p style={{ color: '#666', fontSize: '14px', marginBottom: '24px' }}>
        {quiz.questions.length} questions
      </p>

      {submitted && (
        <div style={{ background: score >= quiz.questions.length * 0.7 ? '#E8F5E9' : '#FFF8E1', borderRadius: radius.md, padding: '16px', marginBottom: '24px', textAlign: 'center' }}>
          <div style={{ fontSize: '32px', fontWeight: 700, color: score >= quiz.questions.length * 0.7 ? '#2E7D32' : '#F57C00' }}>
            {score} / {quiz.questions.length}
          </div>
          <div style={{ fontSize: '14px', color: '#555', marginTop: '4px' }}>
            {score === quiz.questions.length ? 'Perfect score!' : score >= quiz.questions.length * 0.7 ? 'Good work!' : 'Review the explanations below and try again.'}
          </div>
        </div>
      )}

      {quiz.questions.map((q, qi) => {
        const answered = answers[q.id] !== undefined
        const correct = answers[q.id] === q.correct
        return (
          <div key={q.id} style={{ marginBottom: '24px', padding: '20px', background: '#fff', borderRadius: radius.md, boxShadow: '0 1px 4px rgba(0,0,0,0.08)', border: submitted ? `2px solid ${correct ? '#66BB6A' : '#EF5350'}` : '2px solid transparent' }}>
            <div style={{ fontWeight: 600, fontSize: '15px', marginBottom: '12px' }}>
              <span style={{ color: colors.primary, marginRight: '8px' }}>{qi + 1}.</span>
              {q.question}
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {q.options.map((opt, oi) => {
                const isSelected = answers[q.id] === oi
                const isCorrect = oi === q.correct
                let bg = '#F5F5F5'
                let border = '1px solid #E0E0E0'
                if (submitted && isCorrect) { bg = '#E8F5E9'; border = '1px solid #66BB6A' }
                else if (submitted && isSelected && !isCorrect) { bg = '#FFEBEE'; border = '1px solid #EF5350' }
                else if (!submitted && isSelected) { bg = '#EDE7FF'; border = `1px solid ${colors.accent}` }

                return (
                  <button
                    key={oi}
                    type="button"
                    disabled={submitted}
                    onClick={() => !submitted && setAnswers((a) => ({ ...a, [q.id]: oi }))}
                    style={{ background: bg, border, borderRadius: radius.sm, padding: '10px 14px', textAlign: 'left', cursor: submitted ? 'default' : 'pointer', fontSize: '14px' }}
                  >
                    <span style={{ fontWeight: 600, marginRight: '8px', color: colors.primary }}>{String.fromCharCode(65 + oi)}.</span>
                    {opt}
                  </button>
                )
              })}
            </div>
            {submitted && !correct && (
              <div style={{ marginTop: '12px', padding: '10px 14px', background: '#FFF8E1', borderRadius: radius.sm, fontSize: '13px', color: '#555' }}>
                <strong>Explanation: </strong>{q.explanation}
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
