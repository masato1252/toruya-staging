import React, { useState } from 'react'

const SurveyForm = ({ survey, survey_answers, onSubmit, submit_text }) => {
  const [answers, setAnswers] = useState(() => {
    if (!survey_answers) return {};

    // Transform survey_answers into the expected format
    return survey_answers.reduce((acc, answer) => {
      if (answer.text_answer) {
        acc[answer.survey_question_id] = answer.text_answer;
      } else if (answer.survey_option_ids && answer.survey_option_ids.length > 0) {
        acc[answer.survey_question_id] = answer.survey_option_ids.length === 1
          ? answer.survey_option_ids[0].toString()
          : answer.survey_option_ids.map(id => id.toString());
      }
      return acc;
    }, {});
  });

  const handleAnswerChange = (questionId, value, questionType, extraData = null) => {
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

      switch (question.question_type) {
        case 'text':
          return {
            survey_question_id: parseInt(questionId),
            text_answer: value,
            survey_option_ids: []
          };
        case 'single_selection':
        case 'dropdown':
          return {
            survey_question_id: parseInt(questionId),
            text_answer: null,
            survey_option_ids: [parseInt(value)]
          };
        case 'multiple_selection':
          return {
            survey_question_id: parseInt(questionId),
            text_answer: null,
            survey_option_ids: (Array.isArray(value) ? value : [value]).map(v => parseInt(v))
          };
        default:
          return {
            survey_question_id: parseInt(questionId),
            text_answer: null,
            survey_option_ids: []
          };
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
            {question.options.map((option, index) => (
              <label key={option.id || index} className="radio-label">
                <input
                  type="radio"
                  name={`question-${question.id}`}
                  value={option.id}
                  checked={answers[question.id] && option?.id ? answers[question.id] === option.id.toString() : false}
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
            {question.options.map((option, index) => (
              <option key={option.id || index} value={option.id}>
                {option.content}
              </option>
            ))}
          </select>
        )

      case 'multiple_selection':
        return (
          <div className="checkbox-group">
            {question.options.map((option, index) => (
              <label key={option.id || index} className="checkbox-label">
                <input
                  type="checkbox"
                  value={option.id}
                  checked={answers && answers[question.id] && option?.id ? answers[question.id].includes(option.id.toString()) : false}
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
          {survey.description && <div dangerouslySetInnerHTML={{ __html: survey.description.replace(/<p><\/p>/g, '<p></p><br />').replace(/<p style="text-align:start;"><\/p>/g, '<p></p><br />') }} />}
        </div>
      )}

      {survey.questions?.map((question, index) => (
        <div key={question.id || index} className="question-container">
          <label className="question-label">
            {question.required && <span className="required-marker">*</span>}
            <div dangerouslySetInnerHTML={{ __html: question.description.replace(/<p><\/p>/g, '<p></p><br />').replace(/<p style="text-align:start;"><\/p>/g, '<p></p><br />') }} />
          </label>
          {renderQuestion(question)}
        </div>
      ))}

      <div className="form-actions centerize">
        <button type="submit" className="btn btn-tarco" onClick={handleSubmit}>
          {submit_text || I18n.t("action.survey_save")}
        </button>
      </div>
    </div>
  )
}

export default SurveyForm