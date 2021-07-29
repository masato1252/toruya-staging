"use strict"

import React, { useState, useRef, useEffect } from "react";
import { useForm, Controller } from "react-hook-form";

import { CustomMessageServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import { Translator } from "libraries/helper";
import { ErrorMessage, BottomNavigationBar, TopNavigationBar, CiricleButtonWithWord } from "shared/components"

let personalizeKeyword = "";

const CustomMessageEdit =({props}) => {
  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.message
    }
  });
  const textareaRef = useRef();
  const [template, setTemplate] = useState(props.message.template)
  const [cursorPosition, setCursorPosition] = useState(0)

  useEffect(() => {
    textareaRef.current.focus()
  }, [template.length])

  const onDemo = async (data) => {
    let error, response;

    [error, response] = await CustomMessageServices.demo({
      data: _.assign( data, {
        id: props.message.id,
        scenario: props.scenario,
        template: template,
        service_id: props.message.service_id,
        service_type: props.message.service_type
      })
    })
  }

  const onSubmit = async (data) => {
    let error, response;

    [error, response] = await CustomMessageServices.update({
      data: _.assign( data, {
        id: props.message.id,
        scenario: props.scenario,
        template: template,
        service_id: props.message.service_id,
        service_type: props.message.service_type
      })
    })

    window.location = response.data.redirect_to
  }

  const insertKeyword = (keyword) => {
    personalizeKeyword = keyword
    const newTemplate = template.substring(0, cursorPosition) + personalizeKeyword + template.substring(cursorPosition)
    setTemplate(newTemplate)
  }

  const renderCorrespondField = () => {
    switch(props.scenario) {
      case "booking_page_booked":
      case "booking_page_one_day_reminder":
        return (
          <>
            <div className="field-row">{I18n.t(`user_bot.dashboards.settings.custom_message.booking_page.${props.scenario}`)}</div>
            <div className="field-header">{I18n.t("user_bot.dashboards.settings.custom_message.content")}</div>
            <div className="field-row">
              <textarea
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
            <div className="field-row flex-start">
              <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{customer_name}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.customer_name")} </button>
              <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{shop_name}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.shop_name")} </button>
              <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{shop_phone_number}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.shop_phone_number")}</button>
              <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{booking_time}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.reservation_time")} </button>
            </div>
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
        break
    }
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_booking_page_custom_messages_path(props.message.service_id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t("user_bot.dashboards.settings.custom_message.auto_message_label")}
      />
      <div className="field-header">{I18n.t("user_bot.dashboards.settings.custom_message.send_message_label")}</div>
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize transparent">
        <span></span>
        <CiricleButtonWithWord
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
