"use strict";

import React, { useContext, useEffect, useRef } from "react";
import { GlobalContext } from "context/chats/global_state";
import Message from "./message";
import _ from "lodash";

const usePrevious = value => {
  const ref = useRef();
  useEffect(() => {
    ref.current = value;
  });

  return ref.current;
};

const MessageList = () => {
  const { messages, selected_customer_id, getMessages, selected_channel_id, customers, subscription } = useContext(GlobalContext)

  const customer_messages = messages[selected_customer_id] || []
  const messageListRef = useRef(null);

  useEffect(() => {
    getMessages(selected_customer_id)
  }, [subscription, selected_customer_id])

  useEffect(() => {
    messageListRef.current.scrollIntoView({ behavior: "auto" });
  })

  return (
    <div id="chat-box">
      {customer_messages.map((message, index) => <Message message={message} key={`${selected_customer_id}-${index}`} />)}
      <div ref={messageListRef} />
    </div>
  )
}

export default MessageList;
