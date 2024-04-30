import React, { createContext, useReducer, useEffect, useMemo, useContext } from "react";
import { useForm } from "react-hook-form";
import _ from "lodash";

import combineReducer from "context/combine_reducer";
import BookingCreationReducer from "./booking_creation_reducer";
import { SaleServices } from "user_bot/api";
import { responseHandler } from "libraries/helper";

export const GlobalContext = createContext()

export const useGlobalContext = () => {
  return useContext(GlobalContext)
}

const reducers = combineReducer({
  sales_creation_states: BookingCreationReducer,
})

export const GlobalProvider = ({ props, children }) => {
  useEffect(() => {
    // Use setTimeout to update the message after 2000 milliseconds (2 seconds)
    const timeoutId = setTimeout(() => {
      dispatch({
        type: "SET_ATTRIBUTE",
        payload: {
          attribute: "initial",
          value: false
        }
      })
    }, 3000);

    // Cleanup function to clear the timeout if the component unmounts
    return () => clearTimeout(timeoutId);
  }, []);

  const initialValue = useMemo(() => {
    return _.merge(
      reducers(),
      {
        sales_creation_states: {
          id: props.sale_page?.id,
          selected_booking_page: props.sale_page?.selected_booking_page,
          selected_template: props.sale_page?.selected_template,
          template_variables: props.sale_page?.template_variables,
          product_content: props.sale_page?.content,
          selected_staff: props.sale_page?.staff
        }
      }
    )
  }, [])
  const [state, dispatch] = useReducer(reducers, initialValue)
  const hook_form_methods = useForm({});
  const { selected_booking_page, product_content, selected_template, template_variables, selected_staff } = state.sales_creation_states

  const _salePageData = () => {
    return {
      ...state.sales_creation_states,
      business_owner_id: props.business_owner_id,
      selected_booking_page: selected_booking_page.id,
      selected_template: selected_template.id,
      product_content: _.pick(product_content, ["picture", "desc1", "desc2"]),
      selected_staff: _.pick(selected_staff, ["id", "picture", "introduction"])
    }
  }

  const createDraftSalesBookingPage = async () => {
    const [error, response] = await SaleServices.create_sales_booking_page(
      {
        data: _.merge(_salePageData(), { draft: true }),
      }
    )

    responseHandler(error, response)
  }

  const createSalesBookingPage = async () => {
    const [error, response] = await SaleServices.create_sales_booking_page(
      {
        data: _salePageData()
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

  const isStaffSetup = () => {
    return !(!selected_staff || !selected_staff?.picture_url || selected_staff?.picture_url?.length == 0 || selected_staff?.introduction == "")
  }

  const isContentSetup = () => {
    return product_content.picture_url?.length && product_content.desc1 !== "" && product_content.desc2 !== ""
  }

  const isHeaderSetup = () => {
    return selected_template.edit_body.filter(block => block.component === "input").every(filterBlock => template_variables?.[filterBlock.name] != null)
  }

  const isReadyForPreview = () => {
    return selected_booking_page && isHeaderSetup() && isContentSetup() && isStaffSetup()
  }

  return (
    <GlobalContext.Provider value={{
      props,
      ...hook_form_methods,
      ...state.sales_creation_states,
      dispatch,
      createSalesBookingPage,
      createDraftSalesBookingPage,
      isHeaderSetup,
      isContentSetup,
      isStaffSetup,
      isReadyForPreview
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
