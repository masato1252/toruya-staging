"use strict"

import React, { useState, useRef, useEffect } from "react";
import { useForm, Controller } from "react-hook-form";
import TextareaAutosize from 'react-autosize-textarea';

import { CustomMessageServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import { Translator } from "libraries/helper";
import { ErrorMessage, BottomNavigationBar, TopNavigationBar, CircleButtonWithWord } from "shared/components"

let personalizeKeyword = "";

const CustomMessageEdit =({props}) => {
  const { handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.message
    }
  });
  const textareaRef = useRef();
  const [template, setTemplate] = useState(props.message.template)
  const [cursorPosition, setCursorPosition] = useState(0)
  const [before_minutes, setBeforeMinutes] = useState(props.message.before_minutes)
  const [useAfterDays, setUseAfterDays] = useState(!!props.message.after_days)
  const [after_days, setAfterDays] = useState(props.message.after_days)

  useEffect(() => {
    textareaRef.current.focus()
  }, [template.length])

  useEffect(() => {
    if (useAfterDays && template.length === 0) {
      setTemplate(I18n.t("user_bot.dashboards.settings.custom_message.booking_page.use_after_days_default_template", {
        customer_name: "%{customer_name}",
        product_name: "%{product_name}",
        booking_page_url: "%{booking_page_url}"
      }))
    }
  }, [useAfterDays])

  const onDemo = async (data) => {
    await CustomMessageServices.demo({
      data: _.assign( data, {
        id: props.message.id,
        business_owner_id: props.business_owner_id,
        scenario: props.scenario,
        content: template,
        service_id: props.message.service_id,
        service_type: props.message.service_type,
        before_minutes: before_minutes,
        after_days: after_days
      })
    })

    toastr.success(I18n.t("common.deliveried_please_check_message"))
  }

  const onSubmit = async (data) => {
    if (props.scenario === 'survey_custom_reminder') {
      if (!after_days && !before_minutes) {
        toastr.error(I18n.t("user_bot.dashboards.settings.custom_message.survey.timing_required"));
        return;
      }
    }

    let error, response;

    [error, response] = await CustomMessageServices.update({
      data: _.assign( data, {
        id: props.message.id,
        business_owner_id: props.business_owner_id,
        scenario: props.scenario,
        content: template,
        service_id: props.message.service_id,
        service_type: props.message.service_type,
        before_minutes: useAfterDays ? null : before_minutes,
        after_days: useAfterDays ? after_days : null
      })
    })

    window.location = response.data.redirect_to
  }

  const insertKeyword = (keyword) => {
    personalizeKeyword = keyword
    const newTemplate = template.substring(0, cursorPosition) + personalizeKeyword + template.substring(cursorPosition)
    setTemplate(newTemplate)
  }

  const renderVariableButtons = () => {
    switch(props.scenario) {
      case "survey_pending_response":
        return (
          <div className="field-row flex-start">
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{customer_name}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.customer_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{survey_name}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.survey_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{survey_url}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.survey_url")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{reply_survey_url}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.reply_survey_url")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{shop_name}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.shop_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{shop_phone_number}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.shop_phone_number")}</button>
          </div>
        )
      case "activity_pending_response":
      case "activity_accepted_response":
      case "activity_canceled_response":
        return (
          <div className="field-row flex-start">
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{customer_name}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.customer_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{survey_name}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.survey_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{activity_name}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.activity_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{survey_url}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.survey_url")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{reply_survey_url}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.reply_survey_url")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{shop_name}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.shop_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{shop_phone_number}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.shop_phone_number")}</button>
          </div>
        )
      case "activity_one_day_reminder":
      case "activity_custom_message":
        return (
          <div className="field-row flex-start">
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{customer_name}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.customer_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{survey_name}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.survey_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{activity_name}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.activity_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{survey_url}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.survey_url")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{reply_survey_url}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.reply_survey_url")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{shop_name}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.shop_name")} </button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{shop_phone_number}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.shop_phone_number")}</button>
            <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{activity_slot_time_period}") }}> {I18n.t("user_bot.dashboards.surveys.custom_messages.activity_slot_time_period")} </button>
          </div>
        )
    }
  }

  const renderCorrespondField = () => {
    switch(props.scenario) {
      case "survey_pending_response":
      case "activity_pending_response":
      case "activity_accepted_response":
      case "activity_canceled_response":
      case "activity_one_day_reminder":
      case "activity_custom_message":
        return (
          <>
            {
              props.scenario == 'activity_custom_message' ? (
                <>
                  <div className="field-row">
                    <div className="radio-group">
                    {I18n.t("user_bot.dashboards.settings.custom_message.booking_page.auto_message_delivery_time")}
                    <div className="radio-option">
                      <input
                        type="radio"
                        id="before_minutes"
                        name="timing_type"
                        checked={!useAfterDays}
                        onChange={() => setUseAfterDays(false)}
                      />
                      <label htmlFor="before_minutes">
                        {I18n.t("user_bot.dashboards.settings.custom_message.booking_page.before_reservation")}
                        <input
                          type='tel'
                          value={before_minutes}
                          onChange={(event) => {
                            setBeforeMinutes(event.target.value)
                          }}
                          disabled={useAfterDays}
                        />
                        {I18n.t("user_bot.dashboards.settings.custom_message.booking_page.before_minutes_word")}
                      </label>
                    </div>

                    <div className="radio-option">
                      <input
                        type="radio"
                        id="after_days"
                        name="timing_type"
                        checked={useAfterDays}
                        onChange={() => setUseAfterDays(true)}
                      />
                      <label htmlFor="after_days">
                        {I18n.t("user_bot.dashboards.settings.custom_message.booking_page.after_reservation")}
                        <input
                          type='tel'
                          value={after_days}
                          onChange={(event) => {
                            setAfterDays(event.target.value)
                          }}
                          disabled={!useAfterDays}
                        />
                        {I18n.t("user_bot.dashboards.settings.custom_message.booking_page.after_days_word")}
                      </label>
                    </div>
                  </div>
                </div>
                </>
              ) : (
                <>
                  <div className="field-row">
                    {I18n.t(`user_bot.dashboards.surveys.custom_messages.${props.scenario}`)}
                  </div>
                  {props.scenario == 'activity_one_day_reminder' && (
                    <div className="field-row">
                      <div>
                        {I18n.t("user_bot.dashboards.surveys.custom_messages.reminder_message")}<br />
                        <span className="warning">{props.activities_start_dates.join(', ')}</span>
                      </div>
                    </div>
                  )}
                </>
              )
            }

            <div className="field-header">{I18n.t("user_bot.dashboards.settings.custom_message.content")}</div>
            <div className="field-row">
              <TextareaAutosize
                ref={textareaRef}
                autoFocus={true}
                className="extend with-border"
                value={template}
                onChange={(event) => {
                  setTemplate(event.target.value)
                }}
                onBlur={() => {
                  setCursorPosition(textareaRef.current.selectionStart)
                }}
                onClick={() => {
                  setCursorPosition(textareaRef.current.selectionStart)
                }}
              />
            </div>

            {renderVariableButtons()}

            <div className="field-header">{I18n.t("user_bot.dashboards.settings.custom_message.preview")}</div>
            <div className="field-row hint no-border">
              <p className="p-6 bg-gray rounded break-line-content">
                {Translator(template, {...props.message})}
              </p>
            </div>
            <div className="margin-around centerize">
              <button className="btn btn-tarco margin-around m-3" onClick={handleSubmit(onDemo)}>
                {I18n.t("user_bot.dashboards.settings.custom_message.buttons.send_me_mock_message")}
              </button>
            </div>
          </>
        );
    }
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={props.previous_path || Routes.lines_user_bot_survey_custom_messages_path(props.business_owner_id, props.message.service_id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={props.title || I18n.t("user_bot.dashboards.settings.custom_message.auto_message_booking_label")}
      />
      <div className="field-header">{I18n.t("user_bot.dashboards.settings.custom_message.send_message_label")}</div>
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize transparent">
        <span>
        </span>
        <CircleButtonWithWord
          disabled={formState.isSubmitting}
          onHandle={handleSubmit(onSubmit)}
          icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
          word={I18n.t("action.save")}
        />
      </BottomNavigationBar>
    </div>
  )
}

export default CustomMessageEdit;
