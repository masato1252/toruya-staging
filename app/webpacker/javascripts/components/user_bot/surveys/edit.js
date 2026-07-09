
"use strict"

import React, { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import _ from "lodash"

import { CommonServices } from "user_bot/api"
import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord } from "shared/components"
import { responseHandler } from "libraries/helper"
import { compatRead } from "../../../libraries/compat_api";

const SurveyEdit =({props: initialProps}) => {
  const [readyProps, setReadyProps] = useState(
    initialProps.pageContextPath ? null : initialProps,
  );
  const [loadError, setLoadError] = useState(null);

  useEffect(() => {
    if (!initialProps.pageContextPath) return undefined;

    let cancelled = false;
    const attribute = encodeURIComponent(initialProps.attribute || "");
    compatRead(`${initialProps.pageContextPath}?attribute=${attribute}`)
      .then((body) => {
        if (cancelled) return;
        const form = body.data?.edit_form;
        if (!form?.survey) {
          setLoadError("Failed to load survey edit form");
          return;
        }
        setReadyProps({
          ...initialProps,
          ...form,
          survey: form.survey,
        });
      })
      .catch((err) => {
        if (!cancelled) setLoadError(err.message);
      });

    return () => {
      cancelled = true;
    };
  }, [initialProps]);

  const props = readyProps;
  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: props?.survey
      ? {
        ...props.survey,
        active: String(props.survey.active),
      }
      : {},
  });

  useEffect(() => {
    if (!props?.survey) return;
    Object.entries(props.survey).forEach(([key, value]) => {
      setValue(key, key === "active" ? String(value) : value);
    });
  }, [props, setValue]);

  if (loadError) return <p className="danger">{loadError}</p>;
  if (!props?.survey) return <p>{I18n.t("common.processing")}</p>;

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "active":
        return (
          <>
            <label className="field-row flex-start">
              <input name="active" type="radio" value="true" ref={register({ required: true })} />
              {I18n.t("common.public")}
            </label>
            <label className="field-row flex-start">
              <input name="active" type="radio" value="false" ref={register({ required: true })} />
              {I18n.t("common.private")}
            </label>
          </>
        )
      default:
        return null
    }
  }

  const onSubmit = async (data) => {
    console.log("data", data)

    let error, response;
    [error, response] = await CommonServices.update({
      url: Routes.lines_user_bot_survey_path({ business_owner_id: props.business_owner_id, id: props.survey.id }),
      data: _.assign({ survey_form: data }, { attribute: props.attribute }, { business_owner_id: props.business_owner_id })
    })

    responseHandler(error, response)
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={Routes.settings_lines_user_bot_survey_path({ business_owner_id: props.business_owner_id, id: props.survey.id })}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={I18n.t(`user_bot.dashboards.surveys.edit.${props.attribute}_title`)}
            />
            <div className="field-header">{I18n.t(`user_bot.dashboards.surveys.edit.${props.attribute}_title`)}</div>
            {renderCorrespondField()}
            <BottomNavigationBar klassName="centerize transparent">
              <span></span>
              <CircleButtonWithWord
                disabled={formState.isSubmitting}
                onHandle={handleSubmit(onSubmit)}
                icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                word={I18n.t("action.save")}
              />
            </BottomNavigationBar>
          </div>
        </div>
        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default SurveyEdit;