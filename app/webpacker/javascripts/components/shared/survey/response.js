import React from 'react'

const SurveyResponse = ({ response }) => {
  const renderAnswer = (answers, question) => {
    // Get all answers for this question
    const questionAnswers = Array.isArray(answers) ? answers : [answers];

    switch (question.question_type) {
      case 'text':
        return <p className="answer-text">{questionAnswers[0].text_answer}</p>

      case 'single_selection':
        const selectedOption = question.options.find(opt => opt.id === questionAnswers[0].survey_option_id)
        return <p className="answer-text">{selectedOption?.content}</p>

      case 'multiple_selection':
        const optionIds = questionAnswers.map(ans => ans.survey_option_id)
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
      {response.survey.title && (
        <>
          <div className="survey-header">
            <h2>{response.survey.title}</h2>
            {response.survey.description && (
              <p className="survey-description" dangerouslySetInnerHTML={{ __html: response.survey.description }}></p>
            )}
          </div>
        </>
      )}

      <div className="questions-container">
        {response.survey.questions.map(question => {
          const answers = response.question_answers.filter(a => a.survey_question_id === question.id)

          return (
            <div key={question.id} className="question-container">
              <h3 className="question-text">
                <span dangerouslySetInnerHTML={{ __html: question.description }}></span>
                {question.required && <span className="required-marker">*</span>}
              </h3>
              {answers.length > 0 ? (
                renderAnswer(answers, question)
              ) : (
                <p className="no-answer">No answer provided</p>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}

export default SurveyResponse