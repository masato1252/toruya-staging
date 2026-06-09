"use strict";

import React, { useState } from "react";

import { CustomerServices, CommonServices } from "components/user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js'
import ProcessingBar from "shared/processing_bar";

const parseMediaPayload = (text) => {
  if (!text) return null;
  if (typeof text === "object") return text;

  if (typeof text === "string") {
    try {
      return JSON.parse(text);
    } catch (_e) {
      return null;
    }
  }

  return null;
};

const mediaUrl = (payload, preferredKey, fallbackKey) => {
  if (!payload) return "";

  const normalized = {
    previewImageUrl: payload.previewImageUrl || payload.preview_image_url,
    originalContentUrl: payload.originalContentUrl || payload.original_content_url
  };

  return normalized[preferredKey] || normalized[fallbackKey] || "";
};

const Message = ({message, reply_ai_message, ai_question}) => {
  const [processing, setProcessing] = useState(false)
  const mediaPayload = parseMediaPayload(message.text)
  const imageSrc = mediaUrl(mediaPayload, "previewImageUrl", "originalContentUrl")
  const videoSrc = mediaUrl(mediaPayload, "originalContentUrl", "previewImageUrl")
  const videoPoster = mediaUrl(mediaPayload, "previewImageUrl", "originalContentUrl")

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
          {message.is_video ? (
            <video
              className="chat-media"
              controls
              src={videoSrc}
              poster={videoPoster}
            />
          ) : message.is_image ? (
            <img className="chat-media" src={imageSrc} />
          ) : (
            typeof message.text === "string" || typeof message.text === "number"
              ? message.text
              : null
          )}
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
