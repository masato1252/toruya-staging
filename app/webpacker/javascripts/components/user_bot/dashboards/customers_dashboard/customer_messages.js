"use strict"

import React, { useRef, useLayoutEffect, useEffect } from "react";
import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import CustomerBasicInfo from "./customer_basic_info";
import CustomerNav from "./customer_nav";

import useCustomerMessages from "libraries/use_customer_messages"
import Message from "components/management/chats/message";
import { BottomNavigationBar, CircleButtonWithWord } from "shared/components"
import { CustomerServices } from "components/user_bot/api"

import CustomerMessageForm from "./customer_message_form"

const BottomBar = () => {
  const { selected_customer, props, dispatch } = useGlobalContext()

  return (
    <BottomNavigationBar klassName="centerize">
      <button
        className="btn btn-tarco btn-circle btn-bottom-left"
        onClick={
          () => {
            $("#toruyaMessageReplyDifferenceModal").modal("show");
          }
        }>
        <i className="fas fa-question-circle fa-2x"></i>
      </button>
      <button
        className="btn btn-yellow btn-circle btn-save btn-with-word btn-tweak btn-extend-right"
        onClick={
          () => {
            if (confirm(I18n.t("user_bot.dashboards.customer.unread_confirmation_message"))) {
              CustomerServices.unread_message({ business_owner_id: selected_customer.userId, customer_id: selected_customer.id })
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
  const { selected_customer, props, temp_new_messages } = useGlobalContext()
  const { messages, has_more_messages, fetchMessages } = useCustomerMessages(selected_customer)
  const messageListRef = useRef(null);
  let more_message_view;

  useLayoutEffect(() => {
    messageListRef.current.scrollIntoView({ behavior: "auto" });
  }, [messages[messages.length - 1], temp_new_messages])

  useEffect(() => {
    $("#toruyaMessageReplyModal").modal("show");
  }, []);

  if (has_more_messages === true) {
    more_message_view = (
      <div className="centerize">
        <button className="btn btn-gray" onClick={fetchMessages}>
          {I18n.t("action.load_more")}
        </button>
      </div>
    )
  }
  else if (has_more_messages === false) {
    more_message_view = (
      <div className="centerize warning">
        {I18n.t("action.no_more_message")}
      </div>
    )
  }

  if (props.block_toruya_message_reply) {
    return (
      <div className="customer-view">
        <CustomerBasicInfo />
        <CustomerNav />
        <div
          className="margin-around"
          dangerouslySetInnerHTML={{__html: I18n.t("warnings.user_bot.toruya_message_reply_block_message_html", { upgrade_url: props.upgrade_url })}} />
        <div ref={messageListRef} />
      </div>
    )
  }

  return (
    <div className="customer-view">
      <CustomerBasicInfo />
      <CustomerNav />

      <div id="chat-box">
        {more_message_view}
        {[...messages, ...temp_new_messages].map((message, index) => <Message message={message} key={`${message.id}-${index}`} />)}
        <div ref={messageListRef} />
        <CustomerMessageForm />
      </div>

      <BottomBar />
    </div>
  )
}

export default UserBotCustomerMessages;
