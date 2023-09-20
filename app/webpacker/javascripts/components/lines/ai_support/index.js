"use strict";

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import TextareaAutosize from 'react-autosize-textarea';

import { SelectOptions } from "shared/components"
import { CommonServices } from "components/user_bot/api"
import ProcessingBar from "shared/processing_bar";
import I18n from 'i18n-js/index.js.erb';

export const AiSupport = (props) => {
  const { register, watch, setValue, handleSubmit, formState, errors } = useForm({});
  const [ai_response, setAiResponse] = useState("")
  const [processing, setProcessing] = useState(false)

  const onSubmit = async (data) => {
    setProcessing(true)
    let response, error;

    [error, response] = await CommonServices.create({
      url: Routes.lines_ai_support_index_path({format: 'json'}),
      data: _.assign( data, { encrypted_social_service_user_id: props.encrypted_social_service_user_id })
    })
    setProcessing(false)

    if (error) {
      toastr.error(error.response.data.error_message)
    }
    else {
      setAiResponse(response.data["message"])
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
      <TextareaAutosize
        ref={register({ required: true})}
        className="ai-question extend"
        placeholder={I18n.t("ai_support.ask_ai")}
        name="ai_question"
      />
      <button disabled={formState.isSubmitting} onClick={handleSubmit(onSubmit)} className="btn btn-success">
        {I18n.t("ai_support.send_question_to_ai")}
      </button>
      <TextareaAutosize className="extend bg-white text-base text-black" disabled={true} value={ai_response} />
      {ai_response && (
        <button className="btn btn-tarco" onClick={askMoreQuestion}>
          {I18n.t("ai_support.other_question")}
        </button>
      )}
    </>
  )
}

export default AiSupport;
