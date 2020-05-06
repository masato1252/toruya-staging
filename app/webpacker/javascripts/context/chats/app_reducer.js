import _ from "lodash";

const initialState = {
  selected_channel_id: null,
  subscription: null,
  props: null
}

export default (state = initialState, action) => {
  switch(action.type) {
    case "SET_SUBSCRIPTION":
      return {
        ...state,
        subscription: action.payload
      }
    case "SET_PROPS":
      return {
        ...state,
        props: action.payload
      }
    case "SELECT_CHANNEL":
      return {
        ...state,
        selected_channel_id: action.payload
      }
    default:
      return state;
  }
}
