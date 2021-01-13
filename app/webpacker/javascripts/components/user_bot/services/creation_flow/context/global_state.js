import React, { createContext, useReducer, useMemo, useContext } from "react";
import _ from "lodash";

import combineReducer from "context/combine_reducer";
import ServiceCreationReducer from "./service_creation_reducer";
import { OnlineServices } from "user_bot/api";

export const GlobalContext = createContext()

export const useGlobalContext = () => {
  return useContext(GlobalContext)
}

const reducers = combineReducer({
  services_creation_states: ServiceCreationReducer,
})

export const GlobalProvider = ({ props, children }) => {
  const initialValue = useMemo(() => {
    return _.merge(
      reducers(),
      {
        services_creation_states: {
        }
      }
    )
  }, [])
  const [state, dispatch] = useReducer(reducers, initialValue)

  // const _salePageData = () => {
  //   return {
  //     ...state.sales_creation_states,
  //     selected_booking_page: selected_booking_page.id,
  //     selected_template: selected_template.id,
  //     product_content: _.pick(product_content, ["picture", "desc1", "desc2"]),
  //     selected_staff: _.pick(selected_staff, ["id", "picture", "introduction"])
  //   }
  // }
  //
  // const createSalesBookingPage = async () => {
  //   const [error, response] = await SaleServices.create_sales_booking_page(
  //     {
  //       data: _salePageData()
  //     }
  //   )
  //
  //   if (response?.data?.status == "successful") {
  //     dispatch({
  //       type: "SET_ATTRIBUTE",
  //       payload: {
  //         attribute: "sale_page_id",
  //         value: response.data.sale_page_id
  //       }
  //     })
  //   } else {
  //     alert(error?.message || response.data.error_message)
  //   }
  //
  //   return response?.data?.status == "successful"
  // }

  // const isStaffSetup = () => {
  //   return !(!selected_staff || !selected_staff?.picture_url || selected_staff?.picture_url?.length == 0 || selected_staff?.introduction == "")
  // }
  //
  // const isContentSetup = () => {
  //   return product_content.picture_url.length && product_content.desc1 !== "" && product_content.desc2 !== ""
  // }
  //
  // const isHeaderSetup = () => {
  //   return selected_template.edit_body.filter(block => block.component === "input").every(filterBlock => template_variables?.[filterBlock.name] != null)
  // }
  //
  // const isReadyForPreview = () => {
  //   return selected_booking_page && isHeaderSetup() && isContentSetup() && isStaffSetup()
  // }

  return (
    <GlobalContext.Provider value={{
      props,
      ...state.services_creation_states,
      dispatch,
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
