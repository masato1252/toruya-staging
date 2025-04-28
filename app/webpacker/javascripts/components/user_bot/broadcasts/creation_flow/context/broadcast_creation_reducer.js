import _ from "lodash";

const initialState = {
  id: null,
  query_type: null,
  query: null,
  content: "",
  schedule_at: null,
  customers_count: null,
  selected_customers: []
}

export default (state = initialState, action) => {
  const payload = action.payload

  switch(action.type) {
    case "SET_ATTRIBUTE":
      return {
        ...state,
        [payload.attribute]: payload.value,
      }
    case "UPDATE_SELECTED_CUSTOMERS":
      return {
        ...state,
        selected_customer_ids: payload
      }
    default:
      return state;
  }
}

