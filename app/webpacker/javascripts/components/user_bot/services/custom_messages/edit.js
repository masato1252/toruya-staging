"use strict"

import React, { useState, useRef, useEffect } from "react";
import TextareaAutosize from 'react-autosize-textarea';
import { useForm } from "react-hook-form";
import _ from "lodash";

import { CustomMessageServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import { Translator } from "libraries/helper";
import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord } from "shared/components"

let personalizeKeyword = "";

const CustomMessageEdit =({props}) => {
  const { handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.message
    }
  });
  const textareaRef = useRef();
  const [template, setTemplate] = useState(props.message.template)
  const [after_days, setAfterDays] = useState(props.message.right_away === "true" ? "" :  props.message.after_days)
  const [cursorPosition, setCursorPosition] = useState(0)

  useEffect(() => {
    textareaRef.current.focus()
  }, [template.length])

  const onDemo = async (data) => {
    if (!isSendRightAway() && after_days === '') return;

    [error, response] = await CustomMessageServices.demo({
      data: _.assign( data, {
        id: props.message.id,
        business_owner_id: props.business_owner_id,
        scenario: props.scenario,
        content: template,
        service_id: props.message.service_id,
        service_type: props.message.service_type,
        after_days: after_days,
        right_away: isSendRightAway(),
        locale: I18n.locale
      })
    })
  }

  const onSubmit = async (data) => {
    if (!isSendRightAway() && after_days === '') return;

    const [error, response] = await CustomMessageServices.update({
      data: _.assign( data, {
        id: props.message.id,
        business_owner_id: props.business_owner_id,
        scenario: props.scenario,
        content: template,
        service_id: props.message.service_id,
        service_type: props.message.service_type,
        after_days: after_days,
        right_away: isSendRightAway(),
        locale: I18n.locale
      })
    })

    window.location = response.data.redirect_to
  }

  const insertKeyword = (keyword) => {
    personalizeKeyword = keyword
    const newTemplate = template.substring(0, cursorPosition) + personalizeKeyword + template.substring(cursorPosition)
    setTemplate(newTemplate)
  }

  const isSendRightAway = () => {
    return props.message.right_away === "true"
  }

  const renderCorrespondField = () => {
    switch(props.scenario) {
      case "online_service_purchased":
        return (
          <>
            {isSendRightAway() && <div className="field-row">{I18n.t("user_bot.dashboards.settings.custom_message.online_service.online_service_purchased")}</div>}
            {!isSendRightAway() &&
                (
                  <>
                    <div className="field-row">
                      <span>
                        {I18n.t("user_bot.dashboards.settings.custom_message.online_service.after_days_title")}<br />
                        {I18n.t("user_bot.dashboards.settings.custom_message.online_service.online_service_purchased")}
                        <input
                          type='tel'
                          value={after_days}
                          onChange={(event) => {
                            setAfterDays(event.target.value)
                          }}
                        />
                        {I18n.t("user_bot.dashboards.settings.custom_message.online_service.after_days_word")}
                      </span>
                    </div>
                  </>
            )}
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
            <div className="field-row flex-start">
              <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{customer_name}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.customer_name")} </button>
              <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{service_title}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.service_title")} </button>
              <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{service_start_date}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.service_start_date")} </button>
              <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{service_end_date}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.service_end_date")} </button>
              <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{service_url}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.service_url")} </button>
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
    }
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={Routes.lines_user_bot_service_custom_messages_path(props.business_owner_id, props.message.service_id)}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={I18n.t("user_bot.dashboards.settings.custom_message.auto_message_service_label")}
            />
            <div className="field-header">{I18n.t("user_bot.dashboards.settings.custom_message.send_message_label")}</div>
            {renderCorrespondField()}
            <BottomNavigationBar klassName="centerize transparent">
              {!isSendRightAway() && props.message.id && (
                <a className="btn btn-orange btn-circle btn-delete"
                  data-confirm={I18n.t("common.message_delete_confirmation_message")}
                  rel="nofollow"
                  data-method="delete"
                  href={Routes.lines_user_bot_custom_message_path(props.business_owner_id, props.message.id, { service_id: props.message.service_id, service_type: props.message.service_type })}>
                  <i className="fa fa-trash fa-2x" aria-hidden="true"></i>
                </a>
            )}
              <span></span>
              <CircleButtonWithWord
                disabled={formState.isSubmitting || (!isSendRightAway() && after_days === '')}
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

export default CustomMessageEdit;
