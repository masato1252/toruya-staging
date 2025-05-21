import React, { useState, useEffect } from 'react';
import { LocalStorageManager } from 'libraries/local_storage';

import SurveyForm from 'components/shared/survey/form';
import SurveyResponsePreview from 'components/shared/survey/response_preview';
import { CommonServices } from 'user_bot/api';
import { responseHandler } from 'libraries/helper';
import LineIdentificationView from "components/lines/customer_identifications/shared/line_identification_view"
import CustomerIdentification from "components/lines/customer_identifications"

// Is All Required Questions Been Answered
// If all required questions are answered AND line_login_required is true, show LineIdentificationView page
// If all required questions are answered AND (line_login_required is false OR social_customer.social_user_id is not nil) show CustomerIdentification page
// If not all required questions are answered, show SurveyForm page
// The SurveyForm -> SurveyResponse -> LineIdentificationView(If line_login_required is true AND social_customer.social_user_id is nil) -> CustomerIdentification(If line_login_required is false and social_customer.social_user_id is not nil) -> Final Success Page

const SURVEY_ANSWERS_KEY = 'survey_answers';
const EXPIRATION_MINUTES = 30;

// Move getInitialAnswers outside component
const getInitialAnswers = () => {
  return LocalStorageManager.getWithExpiry(SURVEY_ANSWERS_KEY) || [];
};

const SurveyShow = ({ props }) => {
  const { social_user_id, customer_id, had_address } = props.social_customer;
  const [identified_customer, setIdentifiedCustomer] = useState(customer_id)
  const [surveyAnswers, setSurveyAnswers] = useState([]);
  const [answersConfirmed, setAnswersConfirmed] = useState(false);
  const [replySuccess, setReplySuccess] = useState(false);
  const [error, setError] = useState("");
  const [step, setStep] = useState('survey');

  // Initialize answers on component mount
  useEffect(() => {
    const initialAnswers = getInitialAnswers();
    if (initialAnswers.length > 0) {
      setSurveyAnswers(initialAnswers);
      if (areAllRequiredQuestionsAnswered(initialAnswers)) {
        setStep(getNextStep());
      }
    }
  }, []);

  useEffect(() => {
    if (step === 'final') {
      handleSubmitSurvey(surveyAnswers);
    }
  }, [step]);

  useEffect(() => {
    if (answersConfirmed) {
      setStep(getNextStep());
    }
  }, [answersConfirmed]);

  const handleSubmitSurvey = async (formattedAnswers) => {
    const [error, response] = await CommonServices.create({
      url: Routes.surveys_path({ slug: props.survey.slug }),
      data: { survey_answers: formattedAnswers }
    });

    if (error) {
      setReplySuccess(false);
      setError(error.response.data.error_message)
    } else {
      setReplySuccess(true);
    }

    LocalStorageManager.remove(SURVEY_ANSWERS_KEY);
    responseHandler(error, response)
  }

  // SurveyForm submit handler
  const handleSurveySubmit = async (formattedAnswers) => {
    setSurveyAnswers(formattedAnswers);
    LocalStorageManager.setWithExpiry(SURVEY_ANSWERS_KEY, formattedAnswers, EXPIRATION_MINUTES);
    setStep(getNextStep());
  };

  // CustomerIdentification completion handler
  const handleCustomerIdentified = (customer) => {
    setIdentifiedCustomer(customer.customer_id)
    setStep('final');
  };

  // Helper to determine next step after survey
  const getNextStep = () => {
    const lineLoginRequired = props.line_login_required;
    const socialUserId = props.social_customer?.social_user_id;
    if (!answersConfirmed) return 'answers_confirm';
    if (lineLoginRequired && !socialUserId) return 'line_identification';
    if (!identified_customer) return 'customer_identification';
    return 'final';
  };

  // Helper: check if all required questions are answered
  const areAllRequiredQuestionsAnswered = (answers) => {
    if (!props.survey || !props.survey.questions) return false;
    return props.survey.questions.every(question => {
      if (!question.required) return true;
      const answer = (answers || []).find(a => a.survey_question_id === question.id);
      switch (question.question_type) {
        case 'text':
          return answer && answer.text_answer && answer.text_answer.trim() !== '';
        case 'single_selection':
        case 'dropdown':
          return answer && answer.survey_option_ids && answer.survey_option_ids.length > 0;
        case 'multiple_selection':
          return answer && answer.survey_option_ids && answer.survey_option_ids.length > 0;
        case 'activity':
          return answer && answer.survey_activity_id;
        default:
          return true;
      }
    });
  };

  // Render step
  let content;

  if (!props.survey.active) {
    content = (
      <div className="survey-response-form">
        <div className="survey-header">
          <h2>{props.survey.title}</h2>
          {props.survey.description && <div dangerouslySetInnerHTML={{ __html: props.survey.description.replace(/<p><\/p>/g, '<p></p><br />').replace(/<p style="text-align:start;"><\/p>/g, '<p></p><br />') }} />}

          <div className="margin-around warning centerize">
            <h3>{I18n.t('survey.service_closed')}</h3>
          </div>
        </div>
      </div>
    );
  } else if (step === 'survey') {
    content = (
      <SurveyForm
        survey={props.survey}
        onSubmit={handleSurveySubmit}
        survey_answers={surveyAnswers}
        submit_text={I18n.t('action.submit')}
      />
    );
  } else if (step === 'answers_confirm') {
    content = (
      <div>
        <SurveyResponsePreview
          survey={props.survey}
          question_answers={surveyAnswers}
        />
        <div className="survey-preview-actions" style={{ marginTop: 24, textAlign: 'center' }}>
          <button
            className="btn btn-gray"
            style={{ marginRight: 12 }}
            onClick={() => setStep('survey')}
          >
            {I18n.t('action.edit')}
          </button>
          <button
            className="btn btn-yellow"
            onClick={() => {
              setAnswersConfirmed(true);
            }}
          >
            {I18n.t('action.confirm')}
          </button>
        </div>
      </div>
    );
  } else if (step === 'line_identification') {
    content = (
      <div className="bg-white p-6">
        <LineIdentificationView
          line_login_url={props.line_login_url}
        />
      </div>
    );
  } else if (step === 'customer_identification') {
    content = (
      <div className="bg-white p-6">
        <CustomerIdentification
          social_customer={props.social_customer}
          customer={props.customer}
          i18n={{ successful_message_html: (<></>) }}
          support_feature_flags={props.support_feature_flags}
          locale={props.locale}
          user_id={props.user_id}
          identifiedCallback={handleCustomerIdentified}
        />
      </div>
    );
  } else if (step === 'final') {
    if (replySuccess) {
      content = (
        <div className="survey-final mt-5 centerize">
          <h2>{I18n.t('survey.success_title')}</h2>
          <p>{I18n.t('survey.success_message')}</p>
          <a href={Routes.survey_path({ slug: props.survey.slug })} className="btn btn-yellow mt-3">
            {I18n.t('action.back_to_survey')}
          </a>
        </div>
      );
    } else if (error) {
      content = (
        <div className="survey-final mt-5 centerize">
          <h2>{I18n.t('survey.error_title')}</h2>
          <p className="danger margin-around" dangerouslySetInnerHTML={{ __html: error }} />
          <a href={Routes.survey_path({ slug: props.survey.slug })} className="btn btn-yellow mt-3">
            {I18n.t('action.back_to_survey')}
          </a>
        </div>
      );
    }
  }

  return <div className="survey-show">{content}</div>;
};

export default SurveyShow;
