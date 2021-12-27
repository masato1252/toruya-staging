import _ from "lodash";

const initialState = {
  total_customers_number: 0,
  selected_customer: {},
  customers: [],
  is_all_customers_loaded: false,
  query_type: "recent",
  filter_pattern_number: null,
  reservations: [],
  payments: [],
  temp_new_messages: []
}

export default (state = initialState, action) => {
  let new_selected_customer, new_customers;

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
        temp_new_messages: []
      }
    case "UPDATE_CUSTOMER":
      const payload_customer = action.payload.customer
      new_selected_customer = payload_customer.id == state.selected_customer.id ? payload_customer : state.selected_customer
      new_customers = state.customers.map(customer => customer.id == payload_customer.id ? payload_customer : customer)

      return {
        ...state,
        selected_customer: new_selected_customer,
        customers: new_customers
      }
    case "DELETE_CUSTOMER":
      new_customers = state.customers.filter(customer => customer.id !== action.payload.customer_id)

      return {
        ...state,
        selected_customer: {},
        customers: new_customers,
        total_customers_number: state.total_customers_number - 1
      }
    case "UPDATE_CUSTOMER_REMINDER_PERMISSION":
      new_selected_customer = {...state.selected_customer, reminderPermission: action.payload.reminderPermission}
      new_customers = state.customers.map(customer => customer.id == new_selected_customer.id ? new_selected_customer : customer)

      return {
        ...state,
        selected_customer: new_selected_customer,
        customers: new_customers
      }
    case "ASSIGN_CUSTOMER_RESERVATIONS":
      return {
        ...state,
        reservations: action.payload.reservations,
      }
    case "ASSIGN_CUSTOMER_PAYMENTS":
      return {
        ...state,
        payments: action.payload.payments,
      }
    case "APPEND_NEW_MESSAGE":
      return {
        ...state,
        temp_new_messages: [...state.temp_new_messages, action.payload.message],
      }
    default:
      return state;
  }
}
