import React from 'react'

const SurveyResponsePreview = ({ survey, question_answers }) => {
  const renderAnswer = (answers, question) => {
    // Get all answers for this question
    const questionAnswers = Array.isArray(answers) ? answers : [answers];

    switch (question.question_type) {
      case 'empty_block':
        return null; // Empty blocks don't need to show any answer

      case 'text':
        return <p className="answer-text">{questionAnswers[0].text_answer}</p>

      case 'single_selection':
      case 'dropdown':
        const selectedOption = question.options.find(opt => questionAnswers[0].survey_option_ids.includes(opt.id))
        return <p className="answer-text">{selectedOption?.content}</p>

      case 'multiple_selection':
        const optionIds = questionAnswers.map(ans => ans.survey_option_ids).flat()
        const selectedOptions = question.options.filter(opt => optionIds.includes(opt.id))
        return (
          <ul className="answer-list">
            {selectedOptions.map(option => (
              <li key={option.id}>{option.content}</li>
            ))}
          </ul>
        )

      default:
        return null
    }
  }

  return (
    <div className="survey-response">
      <div className="questions-container">
        <div className="survey-header">
          <h2>{survey.title}</h2>
        </div>
        {survey.questions.map(question => {
          const answers = question_answers.filter(a => a.survey_question_id === question.id)

          if (answers.length > 0) {
            return (
              <div key={question.id} className="question-container">
                <h3 className="question-text">
                  {question.required && <span className="required-marker">*</span>}
                  <span dangerouslySetInnerHTML={{ __html: question.description }}></span>
                </h3>
                {renderAnswer(answers, question)}
              </div>
            )
          }
        })}
      </div>
    </div>
  )
}

export default SurveyResponsePreview