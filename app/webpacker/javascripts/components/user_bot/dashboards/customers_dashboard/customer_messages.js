"use strict"

import React, { useContext, useRef, useLayoutEffect } from "react";
import { GlobalContext } from "context/user_bots/customers_dashboard/global_state";
import CustomerBasicInfo from "./customer_basic_info";
import CustomerNav from "./customer_nav";

import useCustomerMessages from "libraries/use_customer_messages"
import Message from "components/management/chats/message";

const UserBotCustomerMessages = () => {
  const { selected_customer } = useContext(GlobalContext)
  const messages = useCustomerMessages(selected_customer)
  const messageListRef = useRef(null);

  useLayoutEffect(() => {
    messageListRef.current.scrollIntoView({ behavior: "auto" });
  }, [messages])

  return (
    <div className="customer-view">
      <CustomerBasicInfo />
      <CustomerNav />

      <div id="chat-box">
        {messages.map((message, index) => <Message message={message} key={`${message.id}-${index}`} />)}
        <div ref={messageListRef} />
      </div>
    </div>
  )
}

export default UserBotCustomerMessages;
