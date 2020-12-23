import React, { createContext, useReducer, useRef, useMemo, useContext } from "react";
import { useForm } from "react-hook-form";

import combineReducer from "context/combine_reducer";
import BookingCreationReducer from "./booking_creation_reducer";

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

  const createSales = async () => {
    // const params = _.merge(
    //   data,
    //   {
    //     end_time_date_part: data.start_time_date_part,
    //     end_time_time_part: end_at().format("HH:mm"),
    //     by_staff_id: props.reservation_form.by_staff_id,
    //     menu_staffs_list,
    //     staff_states,
    //     customers_list,
    //     from: props.params.from,
    //     customer_id: props.params.customer_id
    //   }
    // )
    // const [error, response] = await SalesServices.create_sales_booking_page(
    //   {
    //     data: {
    //     }
    //   }
    // )

    if (response?.data?.status == "successful") {
    }
    else {
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
      createSales
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
