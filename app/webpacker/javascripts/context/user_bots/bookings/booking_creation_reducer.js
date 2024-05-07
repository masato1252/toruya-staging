import _ from "lodash";

const initialState = {
  selected_shop: {},
  selected_menu: {},
  selected_booking_option: {},
  new_booking_option_price: 0,
  new_booking_option_tax_include: true,
  price_type: "regular",
  ticket_quota: 1,
  ticket_expire_month: 1,
  new_menu_name: null,
  new_menu_minutes: null,
  note: null,
  menus: [],
  booking_options: [],
  booking_page_id: null
}

export default (state = initialState, action) => {
  switch(action.type) {
    case "SET_ATTRIBUTE":
      return {
        ...state,
        [action.payload.attribute]: action.payload.value,
      }
    case "RESET_OPTION":
      return {
        ...state,
        new_menu_name: null,
        new_menu_minutes: null,
        selected_menu: {},
        selected_booking_option: {}
      }
    case "SET_NEW_MENU":
      return {
        ...state,
        new_menu_name: action.payload.value,
        selected_menu: {},
        selected_booking_option: {}
      }
    case "SET_MENU":
      return {
        ...state,
        selected_menu: action.payload.menu,
        selected_booking_option: {}
      }
    case "SET_BOOKING_OPTION":
      return {
        ...state,
        selected_booking_option: action.payload.booking_option,
        selected_menu: {},
        new_booking_option_price: 0,
        new_booking_option_tax_include: false
      }
    default:
      return state;
  }
}

