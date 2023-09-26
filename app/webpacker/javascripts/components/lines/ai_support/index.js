"use strict";

import React, { useState, useLayoutEffect } from "react";
import { useForm } from "react-hook-form";
import TextareaAutosize from 'react-autosize-textarea';
import Linkify from 'linkify-react'

import { SelectOptions } from "shared/components"
import { CommonServices } from "components/user_bot/api"
import ProcessingBar from "shared/processing_bar";
import I18n from 'i18n-js/index.js.erb';
import useInterval from 'libraries/use_interval';

export const AiSupport = (props) => {
  const { register, watch, setValue, handleSubmit, formState, errors } = useForm({});
  const [ai_response, setAiResponse] = useState("")
  const [processing, setProcessing] = useState(false)
  const [isAiChecking, setAiChecking] = useState(false);
  const [ai_uid, setAiUid] = useState("")

  useInterval(
    () => {
      checkAiResponse()
    },
    isAiChecking? 3000 : null
  );

  const onSubmit = async (data) => {
    setProcessing(true)
    let response, error;

    [error, response] = await CommonServices.create({
      url: Routes.lines_ai_support_index_path({format: 'json'}),
      data: _.assign( data, { encrypted_social_service_user_id: props.encrypted_social_service_user_id })
    })

    setAiChecking(true)
    setAiUid(response.data["ai_uid"])
  }

  const checkAiResponse = async () => {
    if (!ai_uid) return;

    let [error, response] = await CommonServices.get({
      url: Routes.response_check_lines_ai_support_index_path({format: 'json'}),
      data: { ai_uid: ai_uid, encrypted_social_service_user_id: props.encrypted_social_service_user_id }
    })

    if (response.data["message"]) {
      setAiResponse(response.data["message"])
      setProcessing(false)
      setAiChecking(false)
    }
  }

  const askMoreQuestion = () => {
    setValue("category", "")
    setValue("ai_question", "")
    setAiResponse("")
  }

  return (
    <>
      <ProcessingBar processing={processing} processingMessage={I18n.t("admin.chat.ai_processing")} />
      <div className="reminder-mark margin-around" dangerouslySetInnerHTML={{ __html: I18n.t("ai_support.ai_remind_message_html") }} />
      <label>{I18n.t("ai_support.category_label")}</label>
      {errors["category"] && <div className="danger">{I18n.t("common.required_label")}</div>}
      <select autoFocus={true} name="category" ref={register({ required: true })}>
        <SelectOptions options={props.categories} />
      </select>
      {errors["ai_question"] && <div className="danger">{I18n.t("common.required_label")}</div>}
      {watch("category") && (
        <>
          <TextareaAutosize
            ref={register({ required: true})}
            className="ai-question extend"
            placeholder={I18n.t("ai_support.ask_ai")}
            name="ai_question"
          />
          <button disabled={formState.isSubmitting || processing} onClick={handleSubmit(onSubmit)} className="btn btn-success">
            {I18n.t("ai_support.send_question_to_ai")}
          </button>
        </>
      )}
      <div className="margin-around extend bg-white text-base text-black break-line-content">
        <Linkify>{ai_response}</Linkify>
      </div>

      {ai_response && (
        <button className="btn btn-tarco" onClick={askMoreQuestion}>
          {I18n.t("ai_support.other_question")}
        </button>
      )}
    </>
  )
}

export default AiSupport;
