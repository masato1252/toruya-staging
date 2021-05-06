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
        return (
          <>
            <div className="margin-around m10">
              <h3>Personalize keyword</h3>
              <button className="btn btn-tarco margin-around m-3" onClick={() => { insertKeyword("%{customer_name}") }}> Customer Name </button>
              <button className="btn btn-tarco margin-around m-3" onClick={() => { insertKeyword("%{shop_name}") }}> Shop Name </button>
              <button className="btn btn-tarco margin-around m-3" onClick={() => { insertKeyword("%{shop_phone_number}") }}> Shop phone number</button>
              <button className="btn btn-tarco margin-around m-3" onClick={() => { insertKeyword("%{booking_time}") }}> Reservation time </button>
            </div>
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
            <button className="btn btn-tarco margin-around m-3" onClick={handleSubmit(onDemo)}>
              Send Me Mock message
            </button>
            <div className="field-row hint no-border break-line-content">
              {Translator(template, {...props.message})}
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
        title={"title"}
      />
      <div className="field-header">{"subtitle"}</div>
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
