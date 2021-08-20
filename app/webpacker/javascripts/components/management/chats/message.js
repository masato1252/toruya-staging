"use strict";

import React from "react";
import { CustomerServices, CommonServices } from "components/user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js'

const Message = ({message}) => {
  return (
    <div className="row message">
      <div className={`${message.message_type}`} >
        <div className={`col-sm-10 message-content ${message.sent ? "" : "unsend"}`}>
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
                [error, response] = await CustomerServices.delete_message({ user_id: message.user_id, customer_id: message.toruya_customer_id, message_id: message.id })
              }

              window.location.replace(response?.data?.redirect_to)
            }
          }}
        >
          {message.message_type === "customer" && message.readed && <i className="fa fa-envelope-open" aria-hidden="true"></i>}
          {message.message_type === "bot" && <i className="fa fa-robot" aria-hidden="true"></i>}
          {(message.message_type === "customer_reply_bot" || message.message_type === "user_reply_bot") && <i className="fa fa-hand-point-up" aria-hidden="true"></i> }
          {!message.sent && message.id && <i className="fa fa-trash" aria-hidden="true"></i>}
          {message.formatted_schedule_at && <i className="fa fa-calendar" aria-hidden="true"></i>}
          <p className="message-time">
            {message.sent ? message.formatted_created_at : `${message.formatted_schedule_at}`}
          </p>
        </div>
      </div>
    </div>
  )
}

export default Message;
