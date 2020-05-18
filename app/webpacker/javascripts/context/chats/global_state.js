import React, { createContext, useReducer, useEffect } from "react";
import AppReducer from "context/chats/app_reducer";
import messageReducer from "context/chats/message_reducer";
import customerReducer from "context/chats/customer_reducer";
import combineReducer from "context/combine_reducer";

export const GlobalContext = createContext()
const reducers = combineReducer({
  app: AppReducer,
  message: messageReducer,
  customer: customerReducer
})

export const GlobalProvider = ({ children }) => {
  const [state, dispatch] = useReducer(reducers, reducers())
  const { subscription, selected_channel_id } = state.app
  const { selected_customer } = state.customer
  const { messages } = state.message
  // state = {
  //   app: {...},
  //   message: {...},
  //   customer: {...}
  // }

  const staffNewMessage = (customer_with_message) => {
    dispatch({
      type: "STAFF_NEW_MESSAGE",
      payload: customer_with_message
    })

    subscription.perform("send_message", {
      customer_id: customer_with_message["customer_id"],
      text: customer_with_message["message"]["text"]
    })
  }

  const customerNewMessage = ({ customer, message }) => {
    dispatch({
      type: "CUSTOMER_NEW_MESSAGE",
      payload: {
        customer,
        message
      }
    })
  }

  const prependMessages = ({ customer_id, messages }) => {
    dispatch({
      type: "PREPEND_MESSAGES",
      payload: {
        customer_id: customer_id,
        messages: messages
      }
    })
  }

  const getMessages = (customer_id = null) => {
    if (subscription) {
      const customer_messages = messages[customer_id || selected_customer.id]
      const oldest_message_at = customer_messages ? customer_messages[0].created_at : null

      subscription.perform("get_messages", { customer_id: selected_customer.id, oldest_message_at: oldest_message_at });
    }
  }

  const getCustomers = () => {
    if (subscription) {
      subscription.perform("get_customers", { channel_id: selected_channel_id });
    }
  }

  const toggleCustomerConversationState = (customer) => {
    dispatch({
      type: "TOGGLE_CUSTOMER_CONVERSATION_STATE",
      payload: customer
    })

    subscription.perform("toggle_customer_conversation_state", { customer_id: customer.id });
  }

  return (
    <GlobalContext.Provider value={{
      ...state.app,
      ...state.message,
      ...state.customer,
      dispatch,
      customerNewMessage,
      staffNewMessage,
      getMessages,
      prependMessages,
      getCustomers,
      toggleCustomerConversationState,
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
