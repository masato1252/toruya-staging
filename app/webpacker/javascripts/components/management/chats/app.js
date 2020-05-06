"use strict";

import React, { useEffect, useContext } from "react";

import { GlobalContext } from "context/chats/global_state"
import Consumer from "libraries/consumer";
import CusomterList from "./customer_list"
import MessageList from "./message_list"
import MessageForm from "./message_form"

export default ({ props }) => {
  const { dispatch, prependMessages, getCustomers } = useContext(GlobalContext)

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
              dispatch({
                type: "CUSTOMER_NEW_MESSAGE",
                payload: data
              })
              break;
            case "prepend_messages":
              prependMessages(data)
              break;
            case "append_customers":
              dispatch({
                type: "APPEND_CUSTOMERS",
                payload: {
                  channel_id: data.channel_id,
                  customers: data.customers
                }
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
        <CusomterList />
      </div>
      <div className="col-sm-10">
        <MessageList />
        <MessageForm />
      </div>
    </>
  )
}
