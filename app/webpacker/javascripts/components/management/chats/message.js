"use strict";

import React, { useState } from "react";

import { CustomerServices, CommonServices } from "components/user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js'
import ProcessingBar from "shared/processing_bar";

const Message = ({message, reply_ai_message, ai_question}) => {
  const [processing, setProcessing] = useState(false)

  const aiReply = async () => {
    setProcessing(true)
    ai_question(message.text)
    const [error, resp] = await CommonServices.create({
      url: Routes.ai_reply_admin_chats_path({format: "json"}),
      data: { question: message.text, prompt: localStorage.getItem("prompt") }
    })
    setProcessing(false)

    if (error) {
      alert(error.response.data.error_message)
    }
    else {
      reply_ai_message(resp.data["message"])
    }
  }

  return (
    <div className="row message">
      <ProcessingBar processing={processing} processingMessage={I18n.t("admin.chat.ai_processing")} />
      <div className={`${message.message_type} ${message.id} ${!!message.formatted_schedule_at && !message.sent ? 'scheduled' : ''}`} >
        <div className={`col-sm-10 break-line-content message-content ${message.sent ? "" : "unsend"}`}>
          {message.is_image ? <img className="w-full" src={message.text.previewImageUrl || ""} /> : message.text}
        </div>
        <div
          className="message-icons"
          onClick={async () => {
            let error, response;

            if (message.sent) return;

            if (confirm(I18n.t("common.message_delete_confirmation_message"))) {

              if (message.message_type === 'admin') {
                [error, response] = await CommonServices.delete({
                  url: Routes.admin_chat_path({id: message.id, format: "json"}),
                  data: {
                    customer_id: message.customer_id
                  }
                })
              }
              else {
                [error, response] = await CustomerServices.delete_message({ business_owner_id: message.user_id, customer_id: message.toruya_customer_id, message_id: message.id })
              }

              window.location.replace(response?.data?.redirect_to)
            }
          }}
        >
          {message.channel && <span className="message-channel">{I18n.t(`common.channels.${message.channel}`)}</span>}
          {message.message_type === "bot" && <i className="fa fa-robot" aria-hidden="true"></i>}
          {(message.message_type === "customer_reply_bot" || message.message_type === "user_reply_bot") && <i className="fa fa-hand-point-up" aria-hidden="true"></i> }
          {!message.sent && message.id && <i className="fa fa-trash" aria-hidden="true"></i>}
          {message.formatted_schedule_at && <i className="fa fa-calendar" aria-hidden="true"></i>}
          <p className="message-time">
            {message.sent ? message.formatted_created_at : `${message.formatted_schedule_at}`}
            <br />
            {message.staff_name}
          </p>
        </div>
      </div>
    </div>
  )
}

export default Message;
