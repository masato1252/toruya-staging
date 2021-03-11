"use strict";

import React, { useEffect, useContext } from "react";
import _ from "lodash";

import { GlobalContext } from "context/chats/global_state"
import Consumer from "libraries/consumer";
import useCustomCompareEffect from "libraries/use_custom_compare_effect";
import NotificationPermission from "./notification_permission"
import CusomterList from "./customer_list"
import CusomterInfo from "./customer_info"
import ChatBody from "./body"
import MessageForm from "./message_form"

export default ({ props }) => {
  const {
    dispatch,
    customerNewMessage,
    prependMessages,
    selected_customer,
    customers
  } = useContext(GlobalContext)

  useEffect(() => {
    dispatch({
      type: "SET_PROPS",
      payload: props
    })
  }, [])

  useEffect(() => {
    dispatch({
      type: "SELECT_CHANNEL",
      payload: props.social_channel_id
    })

    dispatch({
      type: "SELECT_CUSTOMER",
      payload: props.social_customer
    })
  }, [])

  useEffect(() => {
    const subscription = Consumer.subscriptions.create(
      {
        channel: props.channel_name || "UserChannel",
        user_id: props.super_user_id
      },
      {
        connected: () => {
          console.log("User Channel connected")

          dispatch({
            type: "SET_SUBSCRIPTION",
            payload: subscription
          })
        },
        disconnected: () => {
          console.log("User Channel disconnected")
        },
        received: ({type, data}) => {
          switch (type) {
            case "customer_new_message":
              customerNewMessage(data)
              break;
            case "prepend_messages":
              prependMessages(data)
              break;
            case "append_customers":
              dispatch({
                type: "APPEND_CUSTOMERS",
                payload: data
              })

              break;
            case "matched_shop_customers":
              dispatch({
                type: "MATCHED_SHOP_CUSTOMERS",
                payload: data
              })

              break;
            case "customer_has_messages":
              dispatch({
                type: "CUSTOMER_HAS_MESSAGES",
                payload: data
              })

              break;
            case "toggle_customer_conversation_state":
              dispatch({
                type: "TOGGLE_CUSTOMER_CONVERSATION_STATE",
                payload: data
              })

              break;
            default:
              console.error({type, data});
          }
        }
      }
    )

    return () => {
      console.log("User Channel closed")
      subscription.unsubscribe()
    }
  }, [])


  useCustomCompareEffect(() => {
    const unread_message_count = Object.values(customers) ? Object.values(customers).flat().reduce((sum, customer) => sum + customer.unread_message_count, 0) : 0

    if (unread_message_count) {
      document.title = `(${unread_message_count}) Toruyaースモールビジネスの顧客管理ツールー`
    }
    else {
      document.title = `Toruyaースモールビジネスの顧客管理ツールー`
    }
  }, [customers], _.isEqual)

  return (
    <>
      <div className="col-sm-2">
        <NotificationPermission />
        <CusomterList />
      </div>
      <div className="col-sm-8">
        <div id="chat-box">
          <ChatBody />
        </div>
        <MessageForm />
      </div>
      <div className="col-sm-2">
        <CusomterInfo />
      </div>
    </>
  )
}
