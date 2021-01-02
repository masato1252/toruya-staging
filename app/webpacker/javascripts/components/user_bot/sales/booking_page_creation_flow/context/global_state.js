import React, { createContext, useReducer, useRef, useMemo, useContext } from "react";
import { useForm } from "react-hook-form";
import _ from "lodash";

import combineReducer from "context/combine_reducer";
import BookingCreationReducer from "./booking_creation_reducer";
import { SaleServices } from "user_bot/api";

export const GlobalContext = createContext()

export const useGlobalContext = () => {
  return useContext(GlobalContext)
}

const reducers = combineReducer({
  sales_creation_states: BookingCreationReducer,
})

export const GlobalProvider = ({ props, children }) => {
  const initialValue = useMemo(() => {
    return _.merge(
      reducers(),
      {
        sales_creation_states: {
          selected_booking_page: props.selected_booking_page
        }
      }
    )
  }, [])
  const [state, dispatch] = useReducer(reducers, initialValue)
  const hook_form_methods = useForm({});

  const createSalesBookingPage = async () => {
    const [error, response] = await SaleServices.create_sales_booking_page(
      {
        data: {
          ...state.sales_creation_states,
          selected_booking_page: state.sales_creation_states.selected_booking_page.id,
          selected_template: state.sales_creation_states.selected_template.id,
          product_content: _.pick(state.sales_creation_states.product_content, ["picture", "desc1", "desc2"]),
          selected_staff: _.pick(state.sales_creation_states.selected_staff, ["id", "picture", "introduction"])
        }
      }
    )

    if (response?.data?.status == "successful") {
      dispatch({
        type: "SET_ATTRIBUTE",
        payload: {
          attribute: "sale_page_id",
          value: response.data.sale_page_id
        }
      })
    } else {
      alert(error?.message || response.data.error_message)
    }

    return response?.data?.status == "successful"
  }

  return (
    <GlobalContext.Provider value={{
      props,
      ...hook_form_methods,
      ...state.sales_creation_states,
      dispatch,
      createSalesBookingPage
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
