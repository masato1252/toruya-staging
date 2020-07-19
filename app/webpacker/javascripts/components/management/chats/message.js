"use strict";

import React from "react";

const Message = ({message}) => {
  return (
    <div className="row message">
      <div className={`col-sm-10 ${message.message_type}`}>
        <p className="message-content">
          {message.text}
        </p>
        {message.message_type === "bot" ? <i className="fa fa-robot" aria-hidden="true"></i> : null}
        {message.message_type === "customer_reply_bot" ? <i className="fa fa-hand-point-up" aria-hidden="true"></i> : null}
        <p className="message-time">
          {message.formatted_created_at}
        </p>
      </div>
    </div>
  )
}

export default Message;
