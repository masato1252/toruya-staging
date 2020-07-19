"use strict";

import React, { useState, useContext } from "react";
import moment from "moment-timezone";

import { GlobalContext } from "context/chats/global_state";

const MessageForm = () => {
  moment.locale('ja');
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
        created_at: Date.now(),
        formatted_created_at: moment(Date.now()).format("llll"),
        message_type: "staff"
      }
    }

    staffNewMessage(new_message)
    setText("")
  }

  if (selected_customer.conversation_state !== "one_on_one") return <></>

  return (
    <div id="chat-form">
      <form className="form-inline" onSubmit={onSubmit}>
        <div className="form-group col-sm-10">
          <textarea
            type="text"
            className="form-control"
            placeholder="Messages for customers..."
            rows="3"
            value={text}
            onChange={(e) => setText(e.target.value)}
          />
        </div>
        <div className="form-group col-sm-2">
          <button type="submit" className="btn btn-success" disabled={!text || !selected_customer.id}>
            Send
          </button>
        </div>
      </form>
    </div>
  )
}

export default MessageForm;
