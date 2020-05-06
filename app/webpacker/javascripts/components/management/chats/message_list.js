"use strict";

import React, { useContext, useEffect, useRef } from "react";
import { GlobalContext } from "context/chats/global_state";
import Message from "./message";

const MessageList = () => {
  const { messages, selected_customer_id, getMessages } = useContext(GlobalContext)
  const customer_messages = messages[selected_customer_id] || []
  const messageListRef = useRef(null);

  useEffect(() => {
    getMessages(selected_customer_id)
  }, [selected_customer_id])

  useEffect(() => {
    messageListRef.current.scrollIntoView({ behavior: "smooth" });
  })

  return (
    <div id="chat-box">
      {customer_messages.map((message, index) => <Message message={message} key={`${selected_customer_id}-${index}`} />)}
      <div ref={messageListRef} />
    </div>
  )
}

export default MessageList;
