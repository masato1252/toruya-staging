"use strict";

import React, { useState, useRef, useContext } from "react";
import moment from "moment-timezone";
import TextareaAutosize from 'react-autosize-textarea';

import { CommonServices } from "components/user_bot/api"
import { GlobalContext } from "context/chats/global_state";
import { SubmitButton } from "shared/components";
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js'
import ProcessingBar from "shared/processing_bar";

const MessageForm = () => {
  moment.locale('ja');
  const ref = useRef()
  const { selected_customer, selected_channel_id, reply_message, ai_question, dispatch } = useContext(GlobalContext)
  const [schedule_at, setScheduleAt] = useState(null)
  const [processing, setProcessing] = useState(false)
  const [prompt, setPrompt] = useState(localStorage.getItem("prompt") || " Context information is below.\n ---------------------\n {context_str}\n ---------------------\n Given the context information and not prior knowledge\n Answer should be always used the same language with question\n Answer should use wordings and terms from documents as possible instead of words or terms from questions\n Answer should always base on context information, don't make up your own answer\n The Answer need to be text format with proper linkbreak to make it readable\n And do not provide reference url in answer.\n If you don't know the answer, always reply in English with 'NO CONTEXT'\n If you find multiple questions at once, just reply 'AIが正しくお返事できるように、ご質問は１つずつ送信してください。'\n answer the query.\n Query: {query_str}\n Answer:")

  const markCorrect = () => {
    CommonServices.create({ url: Routes.correct_admin_ai_index_path() })

    toastr.success("AI Response Correct Submitted")
  }

  const markInCorrect = () => {
    CommonServices.create({ url: Routes.incorrect_admin_ai_index_path() })
    toastr.success("AI Response Incorrect submitted")
  }

  const aiReply = async () => {
    setProcessing(true)
    const [error, resp] = await CommonServices.create({
      url: Routes.ai_reply_admin_chats_path({format: "json"}),
      data: { question: ai_question, prompt: prompt }
    })
    setProcessing(false)
    localStorage.setItem("prompt", prompt);

    if (error) {
      alert(error.response.data.error_message)
    }
    else {
      dispatch({
        type: "REPLY_MESSAGE",
        payload: {
          reply_message: resp.data["message"]
        }
      })
    }
  }

  const buildAiFaqSample = async () => {
    const [error, resp] = await CommonServices.create({
      url: Routes.build_by_faq_admin_ai_index_path({format: "json"}),
      data: { question: ai_question, answer: reply_message }
    })

    if (error) {
      alert(error.response.data.error_message)
    }
    else {
      toastr.success("AI Sample Submitted")
    }
  }

  const handleSubmit = async () => {
    if (!ref.current.value) return;

    const [error, response] = await CommonServices.create({
      url: Routes.admin_chats_path({format: "json"}),
      data: {
        customer_id: selected_customer.id, message: ref.current.value, schedule_at: schedule_at
      }
    })

    ref.current.value = null;

    if (response?.data?.redirect_to) {
      window.location.replace(response?.data?.redirect_to)
    }
  }

  if (!selected_customer.id) return <></>

  return (
    <div id="chat-form">
      <ProcessingBar processing={processing} processingMessage={I18n.t("admin.chat.ai_processing")} />
      <label>AI Question</label>
      <button className="btn btn-orange" onClick={aiReply} >AI Reply</button>
      <TextareaAutosize value={prompt} onChange={(e) => setPrompt(e.target.value) } className="w-full" />
      <TextareaAutosize
        value={ai_question}
        onChange={(e) =>
          dispatch({
            type: "AI_QUESTION",
            payload: {
              ai_question: e.target.value
            }
          })
        }
        className="w-full"
      />
      <TextareaAutosize
        ref={ref}
        className="extend with-border"
        placeholder={I18n.t("admin.chat.reply_placeholder")}
        value={reply_message}
        onChange={(e) =>
          dispatch({
            type: "REPLY_MESSAGE",
            payload: {
              reply_message: e.target.value
            }
          })
        }
      />
      <button onClick={buildAiFaqSample} className="btn btn-success">{I18n.t("admin.chat.build_ai_faq")}</button>
      <div className="text-left">
        <div className="margin-around m10 mt-0">
          <label>
            <input
              type="radio" name="schedule_at"
              checked={schedule_at == null}
              onChange={
                () => setScheduleAt(null)
              }
            />
            {I18n.t("common.send_now_label")}
          </label>
        </div>
        <div className="margin-around m10">
          <label>
            <input
              type="radio" name="send_later"
              checked={schedule_at !== null}
              onChange={
                () => setScheduleAt(moment().format("YYYY-MM-DDTHH:mm"))
              }
            />
            <input
              type="datetime-local"
              value={schedule_at || moment().format("YYYY-MM-DDTHH:mm")}
              onClick={() => setScheduleAt(moment().format("YYYY-MM-DDTHH:mm"))}
              onChange={(e) => setScheduleAt(e.target.value) }
            />
          </label>
        </div>
      </div>
      <div className="form-group col-sm-2">
        <SubmitButton
          handleSubmit={handleSubmit}
          btnWord={schedule_at ? I18n.t("action.save_as_schedule") : I18n.t("action.send_now")}
        />
      </div>
    </div>
  )
}

export default MessageForm;
