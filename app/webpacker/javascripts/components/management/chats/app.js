"use strict";

import React, { useEffect, useContext } from "react";

import { GlobalContext } from "context/chats/global_state"
import Consumer from "libraries/consumer";
import NotificationPermission from "./notification_permission"
import CusomterList from "./customer_list"
import MessageList from "./message_list"
import MessageForm from "./message_form"

export default ({ props }) => {
  const { dispatch, customerNewMessage, prependMessages, selected_customer_id, messages } = useContext(GlobalContext)

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
      payload: props.social_customer_id
    })
  }, [])

  useEffect(() => {
    const subscription = Consumer.subscriptions.create(
      {
        channel: "UserChannel",
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
              customerNewMessage({ ...data, selected_customer_id: selected_customer_id })
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

  return (
    <>
      <div className="col-sm-2">
        <NotificationPermission />
        <CusomterList />
      </div>
      <div className="col-sm-10">
        <MessageList />
        <MessageForm />
      </div>
    </>
  )
}
