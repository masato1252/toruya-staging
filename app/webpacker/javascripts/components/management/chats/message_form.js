"use strict";

import React, { useState, useContext } from "react";
import { GlobalContext } from "context/chats/global_state";

const MessageForm = () => {
  const [text, setText] = useState("")
  const { selected_customer, selected_channel_id, staffNewMessage } = useContext(GlobalContext)

  const onSubmit = (e) => {
    e.preventDefault();

    const new_message = {
      customer_id: selected_customer.id,
      channel_id: selected_channel_id,
      message: {
        customer: false,
        text: text,
        readed: true,
        created_at: Date.now()
      }
    }

    staffNewMessage(new_message)
    setText("")
  }

  return (
    <div id="chat-form">
      <form className="form-inline" onSubmit={onSubmit}>
        <div className="form-group col-sm-10">
          <input
            type="text"
            className="form-control"
            placeholder="Text..."
            value={text}
            onChange={(e) => setText(e.target.value)}
          />
        </div>
        <div className="form-group col-sm-2">
          <button type="submit" className="btn btn-success" disabled={!text}>
            Send
          </button>
        </div>
      </form>
    </div>
  )
}

export default MessageForm;
