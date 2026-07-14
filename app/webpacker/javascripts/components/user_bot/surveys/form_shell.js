import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";

import SurveyBuilder from "components/shared/survey/builder";
import SurveyForm from "components/shared/survey/form";
import { BottomNavigationBar, CircleButtonWithWord, UrlCopyInput } from "components/shared/components";
import { CommonServices } from "user_bot/api";
import { compatRead } from "../../../libraries/compat_api";

const emptySurvey = {
  id: null,
  slug: "",
  title: "",
  description: "",
  questions: [],
};

const errorMessage = (error) =>
  error?.response?.data?.error_message ||
  error?.response?.data?.errors?.message ||
  error?.message ||
  I18n.t("common.error", { defaultValue: "アンケートを保存できませんでした" });

const SurveyFormShell = ({ props }) => {
  const isExisting = Boolean(props.survey_id || props.initialData?.id);
  const [surveyData, setSurveyData] = useState(() => (
    props.pageContextPath && isExisting
      ? null
      : { ...emptySurvey, ...(props.initialData || {}) }
  ));
  const [loadError, setLoadError] = useState(null);
  const [saveState, setSaveState] = useState("idle");
  const [saveError, setSaveError] = useState(null);

  useEffect(() => {
    if (!props.pageContextPath || !isExisting) return undefined;

    let cancelled = false;
    setLoadError(null);

    const separator = props.pageContextPath.includes("?") ? "&" : "?";
    compatRead(`${props.pageContextPath}${separator}attribute=questions`)
      .then((body) => {
        if (cancelled) return;
        const survey = body.data?.edit_form?.survey;
        if (!survey) {
          setLoadError(I18n.t("common.load_error", { defaultValue: "アンケートを読み込めませんでした" }));
          return;
        }
        setSurveyData({ ...emptySurvey, ...survey });
      })
      .catch((error) => {
        if (!cancelled) setLoadError(errorMessage(error));
      });

    return () => {
      cancelled = true;
    };
  }, [isExisting, props.pageContextPath]);

  const handleSubmit = async (data) => {
    setSaveState("saving");
    setSaveError(null);

    const [error, response] = await CommonServices.create({
      url: Routes.upsert_lines_user_bot_surveys_path({
        business_owner_id: props.business_owner_id,
        currency: props.currency,
      }),
      data,
    });

    if (error) {
      const message = errorMessage(error);
      setSaveError(message);
      setSaveState("error");
      if (window.toastr) window.toastr.error(message);
      return;
    }

    setSaveState("saved");
    if (response?.data?.redirect_to) {
      window.location = response.data.redirect_to;
    }
  };

  const handleDelete = async () => {
    if (!window.confirm(I18n.t("common.delete_confirmation_message"))) return;

    setSaveState("saving");
    setSaveError(null);
    const [error, response] = await CommonServices.delete({
      url: Routes.lines_user_bot_survey_path({
        business_owner_id: props.business_owner_id,
        id: surveyData.id,
      }),
    });

    if (error) {
      const message = errorMessage(error);
      setSaveError(message);
      setSaveState("error");
      if (window.toastr) window.toastr.error(message);
      return;
    }

    if (response?.data?.redirect_to) {
      window.location = response.data.redirect_to;
    } else {
      window.location = Routes.lines_user_bot_surveys_path({
        business_owner_id: props.business_owner_id,
      });
    }
  };

  if (loadError) {
    return (
      <div className="margin-around danger" role="alert">
        <p>{loadError}</p>
        <button type="button" className="btn btn-gray" onClick={() => window.location.reload()}>
          {I18n.t("action.retry", { defaultValue: "再読み込み" })}
        </button>
      </div>
    );
  }

  if (!surveyData) {
    return (
      <div className="margin-around centerize" aria-live="polite">
        <i className="fa fa-spinner fa-spin fa-2x" />
        <p>{I18n.t("common.processing")}</p>
      </div>
    );
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view surveys">
          {surveyData.id && (
            <div className="p-3">
              <a
                href={Routes.lines_user_bot_survey_responses_path(props.business_owner_id, surveyData.id)}
                className="btn btn-yellow mr-2"
              >
                {I18n.t("user_bot.dashboards.surveys.responses.title")}
              </a>
              <a
                href={Routes.settings_lines_user_bot_survey_path(props.business_owner_id, surveyData.id)}
                className="btn btn-yellow mr-2"
              >
                {I18n.t("user_bot.dashboards.surveys.settings.title")}
              </a>
            </div>
          )}

          {saveError && <p className="margin-around danger" role="alert">{saveError}</p>}
          {saveState === "saving" && (
            <p className="margin-around" aria-live="polite">
              <i className="fa fa-spinner fa-spin" /> {I18n.t("common.processing")}
            </p>
          )}
          {saveState === "saved" && (
            <p className="margin-around success" role="status">
              {I18n.t("common.update_successfully_message")}
            </p>
          )}

          <SurveyBuilder
            mode={props.mode}
            initialData={surveyData}
            onSubmit={handleSubmit}
            onTitleChange={(title) => setSurveyData((previous) => ({ ...previous, title }))}
            onDescriptionChange={(description) => setSurveyData((previous) => ({ ...previous, description }))}
            onQuestionsChange={(questions) => setSurveyData((previous) => ({ ...previous, questions }))}
            skip_header={false}
            business_owner_id={props.business_owner_id}
            currency={props.currency}
          />

          {surveyData.id && (
            <div className="action-block centerize mb-14">
              <button
                type="button"
                className="btn btn-danger"
                disabled={saveState === "saving"}
                onClick={handleDelete}
              >
                {I18n.t("action.delete")}
              </button>
            </div>
          )}

          <BottomNavigationBar klassName="centerize">
            <CircleButtonWithWord
              klassName="btn btn-tarco btn-circle btn-save btn-tweak btn-with-word btn-bottom-left"
              onHandle={() => window.$ && window.$("#survey-preview-modal").modal("show")}
              icon={<i className="fa fa-eye fa-2x" />}
              word={I18n.t("action.preview")}
            />
            <span />
          </BottomNavigationBar>
        </div>

        <div className="col-sm-6 px-0 hidden-xs">
          <div className="preview-container">
            {surveyData.slug && <UrlCopyInput url={Routes.survey_url(surveyData.slug)} />}
            <div className="fake-mobile-layout surveys">
              <SurveyForm survey={surveyData} onSubmit={() => {}} />
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
              <h4 className="modal-title">{I18n.t("settings.survey.preview_title")}</h4>
            </div>
            <div className="modal-body p-0">
              <SurveyForm survey={surveyData} onSubmit={() => {}} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

SurveyFormShell.propTypes = {
  props: PropTypes.shape({
    business_owner_id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
    currency: PropTypes.string,
    mode: PropTypes.string,
    survey_id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    pageContextPath: PropTypes.string,
    initialData: PropTypes.object,
  }).isRequired,
};

export default SurveyFormShell;
