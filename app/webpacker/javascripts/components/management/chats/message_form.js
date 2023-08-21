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

  const aiReply = async () => {
    setProcessing(true)
    const [error, resp] = await CommonServices.create({
      url: Routes.ai_reply_admin_chats_path({format: "json"}),
      data: { question: ai_question }
    })
    setProcessing(false)

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
