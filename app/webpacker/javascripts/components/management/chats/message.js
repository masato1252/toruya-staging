"use strict";

import React from "react";
import { CustomerServices } from "components/user_bot/api"

const Message = ({message}) => {
  return (
    <div className="row message">
      <div
        className={`col-sm-10 ${message.message_type}`}
        onClick={async () => {
          if (message.sent) return;

          if (confirm("Are you sure?")) {
            const [error, response] = await CustomerServices.delete_message({ user_id: message.user_id, customer_id: message.toruya_customer_id, message_id: message.id })
            window.location.replace(response?.data?.redirect_to)
          }
        }}
      >
        <p className={`message-content ${message.sent ? "" : "unsend"}`}>
          {message.text}
        </p>
        {message.message_type === "bot" ? <i className="fa fa-robot" aria-hidden="true"></i> : null}
        {(message.message_type === "customer_reply_bot" || message.message_type === "user_reply_bot") ? <i className="fa fa-hand-point-up" aria-hidden="true"></i> : null}
        {!message.sent && message.id && (
          <>
            <i className="fa fa-trash" aria-hidden="true"></i>
            <i className="fa fa-calendar" aria-hidden="true"></i>
          </>
        )}
        <p className="message-time">
          {message.sent ? message.formatted_created_at : `Schedule send at: ${message.formatted_schedule_at}`}
        </p>
      </div>
    </div>
  )
}

export default Message;
