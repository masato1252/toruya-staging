"use strict";

import React from "react";

const Message = ({message}) => {
  return (
    <div className="row message">
      <div className={`col-sm-10 ${message.message_type}`}>
        <p className={`message-content`}>
          {message.text}
        </p>
      </div>
    </div>
  )
}

export default Message;
