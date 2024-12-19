"use strict"

import React, { useState, useRef, useEffect } from "react";
import Routes from 'js-routes.js'
import { useForm } from "react-hook-form";
import _ from "lodash";

import { CommonServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import { BottomNavigationBar, CircleButtonWithWord } from "shared/components"

const CustomMessageEdit =({props}) => {
  const { handleSubmit, formState, register, watch } = useForm({
    defaultValues: {
      ...props.message,
      ...props.message.flex_attributes
    }
  });
  const textareaRef = useRef();
  const [content, setContent] = useState(props.message.content || "")
  const [after_days, setAfterDays] = useState(props.message.after_days)
  const [nth_time, setNthTime] = useState(props.message.nth_time)

  useEffect(() => {
    textareaRef.current?.focus()
  }, [content.length])

  const onDemo = async (data) => {
    await CommonServices.create({
      url: Routes.demo_admin_custom_messages_path({scenario: props.scenario, locale: I18n.locale}),
      data: _.assign( data, {
        content: content,
        after_days: after_days,
        nth_time: nth_time,
        flex_template: data.flex_template,
      })
    })
  }

  const onSubmit = async (data) => {
    let error, response;

    if (props.message.id) {
      [error, response] = await CommonServices.update({
        url: Routes.update_admin_custom_messages_path(props.scenario, props.message.id),
        data: _.assign( data, {
          content: content,
          after_days: after_days,
          nth_time: nth_time,
          flex_template: data.flex_template,
        })
      })
    }
    else {
      [error, response] = await CommonServices.create({
        url: Routes.create_admin_custom_messages_path({scenario: props.scenario, locale: I18n.locale}),
        data: _.assign( data, {
          content: content,
          after_days: after_days,
          nth_time: nth_time,
          flex_template: data.flex_template,
          locale: I18n.locale
        })
      })
    }

    if (error) {
      alert(error.response.data.error_message)
    }
    else {
      window.location = response.data.redirect_to
    }
  }

  const renderCorrespondField = () => {
    switch(props.scenario) {
      case "first_booking_page_created":
      case "second_booking_page_created":
      case "eleventh_booking_page_created":
      case "first_customer_data_manually_created":
      case "booking_page_not_enough_page_view":
      case "booking_page_not_enough_booking":
      case "no_new_customer":
      case "line_settings_verified":
      case "user_sign_up":
      case "no_line_settings":
      case "user_message_auto_reply":
        return (
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
              <br />
              <span>
                {'nth time'}<br />
                <input
                  type='tel'
                  value={nth_time}
                  onChange={(event) => {
                    setNthTime(event.target.value)
                  }}
                />
                nth time
              </span>
            </div>
            <div className="field-row">

              <label>
                <input name="content_type" type="radio" value="text" ref={register({ required: true })} /> Text
              </label>
              {
                watch("content_type") == "text" && (
                  <textarea
                    ref={textareaRef}
                    autoFocus={true}
                    className="extend with-border"
                    value={content}
                    onChange={(event) => {
                      setContent(event.target.value)
                    }}
                  />
                )
              }
            </div>

            <div className="field-row">
              <label>
                <input name="content_type" type="radio" value="flex" ref={register({ required: true })} /> Flex
              </label>
              {
                watch("content_type") == "flex" && (
                  <>
                    <input name="flex_template" type="hidden" ref={register({ required: true })} />
                    <input name="title" placeholder="title" type="text" ref={register({ required: true })} />
                    <input name="context" placeholder="context" type="text" ref={register({ required: true })} />
                    <input name="picture_url" placeholder="picture_url" type="text" ref={register({ required: true })} />
                    <input name="content_url" placeholder="content_url" type="text" ref={register({ required: true })} />
                    <input name="button_text" placeholder="button_text" type="text" ref={register({ required: true })} />
                  </>
                )
              }
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
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize transparent">
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
