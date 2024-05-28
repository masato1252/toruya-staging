import React, { createContext, useReducer, useRef, useMemo, useContext } from "react";

import combineReducer from "context/combine_reducer";
import BookingCreationReducer from "context/user_bots/bookings/booking_creation_reducer";
import { BookingServices } from "user_bot/api";

export const GlobalContext = createContext()

export const useGlobalContext = () => {
  return useContext(GlobalContext)
}

const reducers = combineReducer({
  booking_creation_states: BookingCreationReducer,
})

export const GlobalProvider = ({ props, children }) => {
  const initialValue = useMemo(() => {
    return _.merge(
      reducers(),
      {
        booking_creation_states: {
          selected_shop: props.selected_shop,
          note: props.note
        }
      }
    )
  }, [])
  const [state, dispatch] = useReducer(reducers, initialValue)
  const { selected_shop, selected_menu, selected_booking_option, new_booking_option_price, new_booking_option_tax_include, note, new_menu_name, new_menu_minutes, new_menu_online_state, ticket_quota, ticket_expire_month } = state.booking_creation_states;

  const fetchShopMenus = async () => {
    const shop_id = state.booking_creation_states.selected_shop.id

    const [error, response] = await BookingServices.available_options({ business_owner_id: props.business_owner_id, shop_id})

    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "menus",
        value: response.data.menus
      }
    })

    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "booking_options",
        value: response.data.booking_options
      }
    })
  }

  const createBookingPage = async () => {
    const [error, response] = await BookingServices.create_booking_page(
      {
        data: {
          business_owner_id: props.business_owner_id,
          super_user_id: props.super_user_id,
          shop_id: selected_shop.id,
          menu_id: selected_menu.value,
          booking_option_id: selected_booking_option.id,
          new_booking_option_price: new_booking_option_price || 0,
          new_booking_option_tax_include: new_booking_option_tax_include,
          ticket_quota: ticket_quota,
          ticket_expire_month: ticket_expire_month,
          new_menu_name: new_menu_name,
          new_menu_minutes: new_menu_minutes,
          new_menu_online: new_menu_online_state === "online",
          note: note
        }
      }
    )

    if (response?.data?.status == "successful") {
      dispatch({
        type: "SET_ATTRIBUTE",
        payload: {
          attribute: "booking_page_id",
          value: response.data.booking_page_id
        }
      })
    }
    else {
      alert(error?.message || response.data.error_message)
    }

    return response?.data?.status == "successful"
  }

  return (
    <GlobalContext.Provider value={{
      props,
      i18n: props.i18n,
      ...state.booking_creation_states,
      dispatch,
      fetchShopMenus,
      createBookingPage
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
