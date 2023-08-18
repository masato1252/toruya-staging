"use strict";

import React, { useContext, useEffect, useLayoutEffect, useRef } from "react";
import { GlobalContext } from "context/chats/global_state";
import Message from "./message";

const MessageList = () => {
  const { messages, selected_customer, getMessages, subscription, dispatch } = useContext(GlobalContext)
  const customer_messages = messages[selected_customer.id] || []
  const messageListRef = useRef(null);
  const latest_message = customer_messages.length ? customer_messages[customer_messages.length - 1] : {}

  let more_message_view;

  useEffect(() => {
    getMessages(false)
  }, [subscription, selected_customer.id])

  useLayoutEffect(() => {
    messageListRef.current.scrollIntoView({ behavior: "auto" });
  }, [latest_message.created_at, selected_customer.id])

  if (selected_customer.has_more_messages === true) {
    more_message_view = (
      <div className="centerize">
        <button className="btn btn-gray" onClick={() => {
          getMessages(true)
        }}>
          More messages
        </button>
      </div>
    )
  }
  else if (selected_customer.has_more_messages === false) {
    more_message_view = (
      <div className="centerize warning">
        No More messages
      </div>
    )
  }

  return (
    <>
      {more_message_view}
      {customer_messages.map((message, index) => {
        return (
          <Message
            message={message}
            reply_ai_message={(text) => {
              dispatch({
                type: "REPLY_MESSAGE",
                payload: {
                  reply_message: text
                }
              })
            }}
            key={`${selected_customer.id}-${index}`}
          />
        )
      })}
      <div ref={messageListRef} />
    </>
  )
}

export default MessageList;
