import _ from "lodash";

const initialState = {
  notification_messages: [],
}

export default (state = initialState, action) => {
  switch(action.type) {
    case "REMOVE_NOTIFICATION":
      return {
        ...state,
        notification_messages: [...state.notification_messages.slice(0, action.payload.index), ...state.notification_messages.slice(action.payload.index + 1)]
      }
    default:
      return state;
  }
}
