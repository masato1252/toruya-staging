import _ from "lodash";

const initialState = {
  menu_staffs_list: [],
  staff_states: [],
  customers_list: [],
  reservation_errors: {},
  selected_customer: null
}

export default (state = initialState, action) => {
  switch(action.type) {
    case "UPDATE_MENU_STAFFS_LIST":
      return {
        ...state,
        menu_staffs_list: action.payload
      }
    case "UPDATE_RESERVATION_ERRORS":
      return {
        ...state,
        reservation_errors: action.payload
      }
    case "UPDATE_STAFF_STATES":
      return {
        ...state,
        staff_states: _.uniqWith(action.payload, (a, b) => String(a.staff_id) === String(b.staff_id))
      }
    case "UPDATE_CUSTOMERS_LIST":
      return {
        ...state,
        customers_list: action.payload
      }
    case "SELECT_CUSTOMER":
      return {
        ...state,
        selected_customer: action.payload
      }
    default:
      return state;
  }
}
