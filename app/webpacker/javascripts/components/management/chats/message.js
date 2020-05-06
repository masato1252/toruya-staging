"use strict";

import React from "react";

const Message = ({message}) => {
  return (
    <div className="row message">
      <div className={`col-sm-10 ${message.customer ? "customer-message" : "staff-message"}`}>
        <p className={`message-content`}>
          {message.text}
        </p>
      </div>
    </div>
  )
}

export default Message;
