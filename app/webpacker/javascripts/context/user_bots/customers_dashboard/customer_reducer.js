import _ from "lodash";

const initialState = {
  selected_customer: {},
  customers: [],
  is_all_customers_loaded: false,
  query_type: "recent",
  filter_pattern_number: null,
  reservations: []
}

export default (state = initialState, action) => {
  switch(action.type) {
    case "RESET_CUSTOMERS":
      return {
        ...state,
        customers: []
      }
    case "APPEND_CUSTOMERS":
      return {
        ...state,
        customers: action.payload.initial ? action.payload.customers : _.uniqWith([...state.customers, ...action.payload.customers], (a, b) => a.id === b.id),
        is_all_customers_loaded: action.payload.is_all_customers_loaded,
        query_type: action.payload.query_type || state.query_type,
        filter_pattern_number: action.payload.filter_pattern_number || state.filter_pattern_number
      }
    case "SELECT_CUSTOMER":
      return {
        ...state,
        selected_customer: action.payload.customer,
      }
    case "UPDATE_CUSTOMER_REMINDER_PERMISSION":
      return {
        ...state,
        selected_customer: {...state.selected_customer, reminderPermission: action.payload.reminderPermission},
      }
    case "ASSIGN_CUSTOMER_CUSTOMERS":
      return {
        ...state,
        reservations: action.payload.reservations,
      }
    default:
      return state;
  }
}
