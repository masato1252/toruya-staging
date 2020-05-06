import _ from "lodash";

const initialState = {
  selected_customer_id: null,
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
    case "SELECT_CUSTOMER":
      return {
        ...state,
        selected_customer_id: action.payload
      }
    default:
      return state;
  }
}
