"use strict"

import React, { useRef, useLayoutEffect } from "react";
import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import CustomerBasicInfo from "./customer_basic_info";
import CustomerNav from "./customer_nav";

import useCustomerMessages from "libraries/use_customer_messages"
import Message from "components/management/chats/message";
import { BottomNavigationBar, CiricleButtonWithWord } from "shared/components"
import { CustomerServices } from "components/user_bot/api"

import CustomerMessageForm from "./customer_message_form"

const BottomBar = () => {
  const { selected_customer, props, dispatch } = useGlobalContext()

  return (
    <BottomNavigationBar klassName="centerize">
      <span>
      </span>
      <button
        className="btn btn-yellow btn-circle btn-save btn-with-word btn-tweak"
        onClick={
          () => {
            if (confirm(I18n.t("user_bot.dashboards.customer.unread_confirmation_message"))) {
              CustomerServices.unread_message({ user_id: selected_customer.userId, customer_id: selected_customer.id })
              dispatch({type: "CHANGE_VIEW", payload: { view: "customer_info_view" }})
            }
          }
        }>
        <i className="fas fa-user-clock fa-2x"></i>
        <div className="word">{I18n.t("user_bot.dashboards.customer.reply_later")}</div>
      </button>
    </BottomNavigationBar>
  )
}

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

      <BottomBar />
    </div>
  )
}

export default UserBotCustomerMessages;
