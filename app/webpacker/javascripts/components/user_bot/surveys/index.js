import React, { useState, useCallback } from 'react';

import { CommonServices } from "user_bot/api"
import SurveyBuilder from 'components/shared/survey/builder';
import SurveyForm from 'components/shared/survey/form';
import { responseHandler } from 'libraries/helper';
import { BottomNavigationBar, CircleButtonWithWord, UrlCopyInput } from 'components/shared/components';

const SurveyIndex = ({ props }) => {
  const [surveyData, setSurveyData] = useState({
    id: props.initialData?.id || '',
    slug: props.initialData?.slug || '',
    title: props.initialData?.title || '',
    description: props.initialData?.description || '',
    questions: props.initialData?.questions || []
  });

  const handleTitleChange = (title) => {
    setSurveyData(prev => ({
      ...prev,
      title
    }));
  };

  const handleDescriptionChange = (description) => {
    setSurveyData(prev => ({
      ...prev,
      description
    }));
  };

  const handleQuestionsChange = (questions) => {
    setSurveyData(prev => ({
      ...prev,
      questions
    }));
  };

  const handleSubmit = async (data) => {
    data.questions.forEach(question => {
      question.activities.forEach(activity => {
        activity.datetime_slots.forEach(slot => {
          slot.start_time = `${slot.start_date} ${slot.start_time}`;
          slot.end_time = `${slot.start_date} ${slot.end_time}`;
        });
      });
    });
    console.log("data", data)
    const [error, response] = await CommonServices.create({
      url: Routes.upsert_lines_user_bot_surveys_path({
        business_owner_id: props.business_owner_id,
        currency: props.currency
      }),
      data: data
    });

    responseHandler(error, response)
  };

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view surveys">
            <div className="p-3">
              {props.has_activities && (
                <a href={Routes.lines_user_bot_survey_activities_path(props.business_owner_id, surveyData?.id)} className="btn btn-yellow mr-2">
                  {I18n.t('user_bot.dashboards.surveys.activities.title')}
                </a>
              )}

              {!props.has_activities && surveyData?.id && (
                <a href={Routes.lines_user_bot_survey_responses_path(props.business_owner_id, surveyData?.id)} className="btn btn-yellow mr-2">
                  {I18n.t('user_bot.dashboards.surveys.responses.title')}
                </a>
              )}

              {surveyData?.id && (
                <a href={Routes.settings_lines_user_bot_survey_path(props.business_owner_id, surveyData?.id)} className="btn btn-yellow mr-2">
                  {I18n.t('user_bot.dashboards.surveys.settings.title')}
                </a>
              )}
          </div>
          <SurveyBuilder
            mode={props.mode}
            initialData={surveyData}
            onSubmit={handleSubmit}
            onTitleChange={handleTitleChange}
            onDescriptionChange={handleDescriptionChange}
            onQuestionsChange={handleQuestionsChange}
            skip_header={false}
            business_owner_id={props.business_owner_id}
            currency={props.currency}
          />

          {/* Delete Button */}
          {surveyData?.id && (
            <div class="action-block centerize mb-14">
              <button className="btn btn-danger" onClick={async () => {
                if (confirm(I18n.t('common.delete_confirmation_message'))) {
                  const [error, response] = await CommonServices.delete({
                  url: Routes.lines_user_bot_survey_path({ business_owner_id: props.business_owner_id, id: surveyData?.id })
                });
                responseHandler(error, response)
                }
              }}>{I18n.t('action.delete')}</button>
            </div>
          )}

          <BottomNavigationBar klassName="centerize">
            <CircleButtonWithWord
              klassName="btn btn-tarco btn-circle btn-save btn-tweak btn-with-word btn-bottom-left"
              onHandle={() => {
                $('#survey-preview-modal').modal('show');
              }}
              icon={<i className="fa fa-eye fa-2x"></i>}
              word={I18n.t("action.preview")}
            />
            <span></span>
          </BottomNavigationBar>
        </div>

        {/* Preview Section */}
        <div className="col-sm-6 px-0 hidden-xs">
          <div className="preview-container">
            <div>
              {surveyData?.slug && (
                <UrlCopyInput url={Routes.survey_url(surveyData.slug)} />
              )}
            </div>
            <div className="fake-mobile-layout surveys">
              <SurveyForm
                survey={surveyData}
                onSubmit={() => {}}
              />
            </div>
          </div>
        </div>
      </div>

      <div className="modal fade" id="survey-preview-modal" tabIndex="-1" role="dialog">
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">×</span>
              </button>
              <h4 className="modal-title" id="myModalLabel">
                {I18n.t('settings.survey.preview_title')}
              </h4>
            </div>
            <div className="modal-body p-0">
              <SurveyForm
                survey={surveyData}
                onSubmit={() => {}}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SurveyIndex;