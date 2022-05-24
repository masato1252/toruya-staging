"use strict"

import React, { useState, useRef, useEffect } from "react";
import Routes from 'js-routes.js'
import { useForm } from "react-hook-form";
import _ from "lodash";

import { CommonServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import { BottomNavigationBar, CiricleButtonWithWord } from "shared/components"

const CustomMessageEdit =({props}) => {
  const { handleSubmit, formState, register, watch } = useForm({
    defaultValues: {
      ...props.message,
      ...props.message.flex_attributes,
      flex_template: "video_description_card"
    }
  });
  const textareaRef = useRef();
  const [content, setContent] = useState(props.message.content || "")
  const [after_days, setAfterDays] = useState(props.message.after_days)

  useEffect(() => {
    textareaRef.current?.focus()
  }, [content.length])

  const onDemo = async (data) => {
    await CommonServices.create({
      url: Routes.demo_admin_custom_messages_path({scenario: props.scenario}),
      data: _.assign( data, {
        content: content,
        after_days: after_days
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
          after_days: after_days
        })
      })
    }
    else {
      [error, response] = await CommonServices.create({
        url: Routes.create_admin_custom_messages_path({scenario: props.scenario}),
        data: _.assign( data, {
          content: content,
          after_days: after_days
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
      case "user_sign_up":
        return (
          <>
            <div className="field-row">
              <span>
                {I18n.t("user_bot.dashboards.settings.custom_message.online_service.after_days_title")}<br />
                <input
                  type='tel'
                  value={after_days}
                  onChange={(event) => {
                    setAfterDays(event.target.value)
                  }}
                />
                {I18n.t('common.day_word')}
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
