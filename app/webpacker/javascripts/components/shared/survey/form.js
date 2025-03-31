import React, { useState } from 'react'

const SurveyForm = ({ survey, onSubmit, survey_answers }) => {
  const [answers, setAnswers] = useState(() => {
    if (!survey_answers) return {};

    // Transform survey_answers into the expected format
    return survey_answers.reduce((acc, answer) => {
      if (answer.text_answer) {
        acc[answer.survey_question_id] = answer.text_answer;
      } else if (answer.survey_option_ids) {
        acc[answer.survey_question_id] = answer.survey_option_ids.length === 1
          ? answer.survey_option_ids[0].toString()
          : answer.survey_option_ids.map(id => id.toString());
      }
      return acc;
    }, {});
  });

  const handleAnswerChange = (questionId, value, questionType) => {
    if (questionType === 'multiple_selection') {
      const currentValues = answers[questionId] || []
      const newValues = currentValues.includes(value)
        ? currentValues.filter(v => v !== value)
        : [...currentValues, value]

      setAnswers({
        ...answers,
        [questionId]: newValues
      })
    } else {
      setAnswers({
        ...answers,
        [questionId]: value
      })
    }
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    // Validate all required questions
    const hasInvalidAnswers = survey.questions.some(question => {
      if (!question.required) return false;

      const answer = answers[question.id];
      switch (question.question_type) {
        case 'text':
          return !answer || answer.trim() === '';
        case 'single_selection':
        case 'dropdown':
          return !answer;
        case 'multiple_selection':
          return !answer || answer.length === 0;
        default:
          return false;
      }
    })

    if (hasInvalidAnswers) {
      alert(I18n.t('errors.please_answer_all_required_questions'))
      return
    }

    // Format answers for the API
    const formattedAnswers = Object.entries(answers).map(([questionId, value]) => {
      const question = survey.questions.find(q => q.id === parseInt(questionId))

      return {
        survey_question_id: parseInt(questionId),
        text_answer: question.question_type === 'text' ? value : null,
        survey_option_ids: question.question_type === 'single_selection' || question.question_type === 'dropdown'
          ? [parseInt(value)]
          : question.question_type === 'multiple_selection'
            ? (Array.isArray(value) ? value : [value]).map(v => parseInt(v))
            : []
      }
    })

    onSubmit(formattedAnswers)
  }

  const renderQuestion = (question) => {
    switch (question.question_type) {
      case 'text':
        return (
          <textarea
            value={answers[question.id] || ''}
            onChange={(e) => handleAnswerChange(question.id, e.target.value, question.question_type)}
            className="form-textarea"
            rows="3"
            required={question.required}
          />
        )

      case 'single_selection':
        return (
          <div className="radio-group">
            {question.options.map(option => (
              <label key={option.id} className="radio-label">
                <input
                  type="radio"
                  name={`question-${question.id}`}
                  value={option.id}
                  checked={answers[question.id] === option.id.toString()}
                  onChange={(e) => handleAnswerChange(question.id, e.target.value, question.question_type)}
                  required={question.required}
                />
                {option.content}
              </label>
            ))}
          </div>
        )

      case 'dropdown':
        return (
          <select
            value={answers[question.id] || ''}
            onChange={(e) => handleAnswerChange(question.id, e.target.value, question.question_type)}
            className="form-select"
            required={question.required}
          >
            <option value="">{I18n.t('common.select')}</option>
            {question.options.map(option => (
              <option key={option.id} value={option.id}>
                {option.content}
              </option>
            ))}
          </select>
        )

      case 'multiple_selection':
        return (
          <div className="checkbox-group">
            {question.options.map(option => (
              <label key={option.id} className="checkbox-label">
                <input
                  type="checkbox"
                  value={option.id}
                  checked={(answers[question.id] || []).includes(option.id.toString())}
                  onChange={(e) => handleAnswerChange(question.id, e.target.value, 'multiple_selection')}
                />
                {option.content}
              </label>
            ))}
          </div>
        )

      default:
        return null
    }
  }

  return (
    <div className="survey-response-form">
      {survey.title && (
        <div className="survey-header">
          <h2>{survey.title}</h2>
          {survey.description && <p>{survey.description}</p>}
        </div>
      )}

      {survey.questions.map(question => (
        <div key={question.id} className="question-container">
          <label className="question-label">
            <div dangerouslySetInnerHTML={{ __html: question.description }} />
            {question.required && <span className="required-marker">*</span>}
          </label>
          {renderQuestion(question)}
        </div>
      ))}

      <div className="form-actions centerize">
        <button type="submit" className="btn btn-tarco" onClick={handleSubmit}>
          {I18n.t("action.survey_save")}
        </button>
      </div>
    </div>
  )
}

export default SurveyForm