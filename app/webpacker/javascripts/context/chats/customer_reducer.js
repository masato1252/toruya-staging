import _ from "lodash";

// mapping with
// app/serializers/customer_serializer.rb
//
// @customers:
// {
//   <channel_id> => [
//      {
//        id : <customer social user id>
//        channel_id: <channel_id>,
//        name: <message name>,
//        unread_message_count: 0,
//        last_message_at: <Datetime>,
//        conversation_state: bot|one_on_one
//      },
//   ]
// }

const initialState = {
  selected_customer: {},
  customers: {},
}

export default (state = initialState, action) => {
  switch(action.type) {
    case "APPEND_CUSTOMERS":
      return {
        ...state,
        customers: {
          ...state.customers,
          [action.payload.channel_id]: [...(state.customers[action.payload.channel_id] || []), ...action.payload.customers ]
        }
      }
    case "CUSTOMER_NEW_MESSAGE":
      if (state.selected_customer.id !== action.payload.customer.id) {
        channel_customers = state.customers[action.payload.customer.channel_id] || []

        return {
          ...state,
          customers: {
            ...state.customers,
            [action.payload.customer.channel_id]: channel_customers.map(el => (el.id === action.payload.customer.id ? {...el, unread_message_count: el.unread_message_count + 1} : el))
          }
        }
      }
      else {
        return state
      }
    case "SELECT_CUSTOMER":
      if (action.payload) {
        channel_customers = state.customers[action.payload.channel_id] || []

        return {
          ...state,
          selected_customer: action.payload,
          customers: {
            ...state.customers,
            [action.payload.channel_id]: channel_customers.map(el => (el.id === action.payload.id ? {...el, unread_message_count: 0} : el))
          }
        }
      }
      else {
        return state
      }
    case "TOGGLE_CUSTOMER_CONVERSATION_STATE":
      channel_customers = state.customers[action.payload.channel_id] || []

      return {
        ...state,
        customers: {
          ...state.customers,
          [action.payload.channel_id]: channel_customers.map(el => (el.id === action.payload.id ? {...el, conversation_state: el.conversation_state === "one_on_one" ? "bot" : "one_on_one"} : el))
        }
      }
    default:
      return state;
  }
}
