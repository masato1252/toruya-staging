import _ from "lodash";

const initialState = {
  selected_customer: null,
  customers: [],
  is_all_customers_loaded: false,
  customer_query_type: "recent"
}

export default (state = initialState, action) => {
  switch(action.type) {
    case "APPEND_CUSTOMERS":
      return {
        ...state,
        customers: action.payload.initial ? action.payload.customers : _.uniqWith([...state.customers, ...action.payload.customers], (a, b) => a.id === b.id),
        is_all_customers_loaded: action.payload.is_all_customers_loaded,
        customer_query_type: action.payload.customer_query_type || state.customer_query_type,
      }
    case "SELECT_CUSTOMER":
      return {
        ...state,
        selected_customer: action.payload.customer,
      }
    default:
      return state;
  }
}
