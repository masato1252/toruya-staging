"use strict";

import React, { useContext, useEffect, useLayoutEffect, useRef } from "react";
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
  const { messages, selected_customer, getMessages, selected_channel_id, customers, subscription } = useContext(GlobalContext)

  const customer_messages = messages[selected_customer.id] || []
  const messageListRef = useRef(null);

  useEffect(() => {
    getMessages(selected_customer)
  }, [subscription, selected_customer.id])

  useLayoutEffect(() => {
    messageListRef.current.scrollIntoView({ behavior: "auto" });
  })

  return (
    <div id="chat-box">
      {customer_messages.map((message, index) => <Message message={message} key={`${selected_customer.id}-${index}`} />)}
      <div ref={messageListRef} />
    </div>
  )
}

export default MessageList;
