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

  const getMessages = (manual) => {
    if (subscription && selected_customer.id) {
      const customer_messages = messages[selected_customer.id]
      const oldest_message = customer_messages ? customer_messages[0] : null

      if ((!manual && oldest_message) || selected_customer.has_more_messages === false) return;

      subscription.perform("get_messages", {
        customer_id: selected_customer.id,
        oldest_message_at: oldest_message ? oldest_message.created_at : null,
        oldest_message_id: oldest_message ? oldest_message.id : null
      });
    }
  }

  const getCustomers = (last_updated_at = null) => {
    console.log({ subscription, selected_channel_id, last_updated_at })
    if (subscription) {
      subscription.perform("get_customers", { channel_id: selected_channel_id, last_updated_at: last_updated_at});
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
