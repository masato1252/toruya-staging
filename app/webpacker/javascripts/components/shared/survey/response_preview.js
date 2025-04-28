import React from 'react'
import { formatActivitySlotRange } from 'libraries/helper';
import moment from 'moment';

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

      case 'activity':
        const selectedActivity = question.activities?.find(activity => activity.id === questionAnswers[0].survey_activity_id);
        return (
          <div className="activity-selection">
            <div className="activity-period">
              <h4>{selectedActivity?.name || I18n.t('settings.survey.period_name_placeholder')}</h4>

              {/* Time Slot Display */}
              <div className="time-slot-display">
                <div className="time-slots">
                  {selectedActivity?.datetime_slots?.map((slot, slotIndex) => (
                    <div key={slotIndex} className="datetime-slot">
                      <div className="time-info">
                        {formatActivitySlotRange(slot)}
                      </div>
                    </div>
                  ))}
                </div>
                <div className="activity-info">
                  {selectedActivity?.max_participants > 0 && (
                    <p className="participants-info">
                      {I18n.t('settings.survey.participants_range', {
                        max: selectedActivity.max_participants
                      })}
                    </p>
                  )}
                  {selectedActivity?.price_cents > 0 && (
                    <p className="price-info">
                      {I18n.t('settings.survey.price_display', {
                        price: selectedActivity.price_cents
                      })}
                    </p>
                  )}
                </div>
              </div>
            </div>
          </div>
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