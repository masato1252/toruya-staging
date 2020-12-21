"use strict"

import React, { useRef, useLayoutEffect } from "react";
import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import CustomerBasicInfo from "./customer_basic_info";
import CustomerNav from "./customer_nav";

import useCustomerMessages from "libraries/use_customer_messages"
import Message from "components/management/chats/message";
import { BottomNavigationBar, CiricleButtonWithWord } from "shared/components"

import CustomerMessageForm from "./customer_message_form"

const UserBotCustomerMessages = () => {
  const { selected_customer, temp_new_messages } = useGlobalContext()
  const messages = useCustomerMessages(selected_customer)
  const messageListRef = useRef(null);

  useLayoutEffect(() => {
    messageListRef.current.scrollIntoView({ behavior: "auto" });
  }, [messages, temp_new_messages])

  return (
    <div className="customer-view">
      <CustomerBasicInfo />
      <CustomerNav />

      <div id="chat-box">
        {[...messages, ...temp_new_messages].map((message, index) => <Message message={message} key={`${message.id}-${index}`} />)}
        <div ref={messageListRef} />
        <CustomerMessageForm />
      </div>
    </div>
  )
}

export default UserBotCustomerMessages;
