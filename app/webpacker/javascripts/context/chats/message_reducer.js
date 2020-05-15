import _ from "lodash";

const initialState = {
  messages: {},
  last_notification_message: {}
}

export default (state = initialState, action) => {
  switch(action.type) {
    case "PREPEND_MESSAGES":
      const new_messages = [...action.payload.messages, ...(state.messages[action.payload.customer_id] || [])]

      return {
        ...state,
        messages: {
          ...state.messages,
          [action.payload.customer_id]: _.uniqWith(new_messages, (a, b) => a.id === b.id)
        }
      }
    case "STAFF_NEW_MESSAGE":
      return {
        ...state,
        messages: {
          ...state.messages,
          [action.payload.customer_id]: [...(state.messages[action.payload.customer_id] || []), action.payload.message]
        }
      }
    case "CUSTOMER_NEW_MESSAGE":
      return {
        ...state,
        messages: {
          ...state.messages,
          [action.payload.customer.id]: [...(state.messages[action.payload.customer.id] || []), action.payload.message]
        },
        last_notification_message: action.payload.message
      }
    default:
      return state;
  }
}
