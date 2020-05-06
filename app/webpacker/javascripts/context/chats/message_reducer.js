import _ from "lodash";

const initialState = {
  messages: {},
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
    case "CUSTOMER_NEW_MESSAGE":
      return {
        ...state,
        messages: {
          ...state.messages,
          [action.payload.customer_id]: [...(state.messages[action.payload.customer_id] || []), action.payload.message]
        }
      }
    default:
      return state;
  }
}
