import React, { createContext, useReducer, useMemo, useContext, useEffect } from "react";
import { useForm } from "react-hook-form";
import _ from "lodash";

import combineReducer from "context/combine_reducer";
import SaleCreationReducer from "./sale_creation_reducer";
import { SaleServices } from "user_bot/api";
import { responseHandler } from "libraries/helper";

export const GlobalContext = createContext()

export const useGlobalContext = () => {
  return useContext(GlobalContext)
}

const reducers = combineReducer({
  sales_creation_states: SaleCreationReducer,
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
          ...props.sale_page,
          selected_online_service: props.sale_page?.selected_online_service || props.selected_online_service,
          product_content: props.sale_page?.content,
          selected_staff: props.sale_page?.staff,
          quantity: props.sale_page?.quantity_option
        }
      }
    )
  }, [])
  const [state, dispatch] = useReducer(reducers, initialValue)
  const hook_form_methods = useForm({});

  const { selected_online_service, product_content, selected_template, template_variables, selected_staff, price, normal_price, end_time, quantity, introduction_video } = state.sales_creation_states

  const _salePageData = () => {
    let submittedData = {
      ...state.sales_creation_states,
      business_owner_id: props.business_owner_id,
      selected_online_service_id: selected_online_service.id,
      selected_template_id: selected_template.id,
      content: _.pick(product_content, ["picture", "desc1", "desc2"]),
      staff: _.pick(selected_staff, ["id", "picture", "introduction"]),
      normal_price: normal_price['price_amount'],
      selling_end_at: end_time["end_time_date_part"],
      quantity: quantity["quantity_value"],
      introduction_video_url: introduction_video["url"]
    }

    if (price && price.price_types.includes("one_time")) {
      submittedData = {
        ...submittedData,
        selling_price: price.price_amounts.one_time.amount,
      }
    }

    if (price && price.price_types.includes("multiple_times")) {
      submittedData = {
        ...submittedData,
        selling_multiple_times_price: price.price_amounts.multiple_times
      }
    }

    if (price && price.price_types.includes("month")) {
      submittedData = {
        ...submittedData,
        monthly_price: price.price_amounts.month.amount,
      }
    }

    if (price && price.price_types.includes("year")) {
      submittedData = {
        ...submittedData,
        yearly_price: price.price_amounts.year.amount,
      }
    }

    return submittedData
  }

  const createDraftSalesOnlineServicePage = async () => {
    const [error, response] = await SaleServices.create_sales_online_service(
      {
        data: _.merge(_salePageData(), { draft: true }),
      }
    )

    responseHandler(error, response)
  }

  const createSalesOnlineServicePage = async () => {
    const [error, response] = await SaleServices.create_sales_online_service(
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
    return product_content?.picture_url?.length && product_content.desc1 !== "" && product_content.desc2 !== ""
  }

  const isHeaderSetup = () => {
    return selected_template?.edit_body?.filter(block => block.component === "input").every(filterBlock => template_variables?.[filterBlock.name] != null)
  }

  const isNormalPriceSetup = () => {
    return normal_price.price_type === 'cost' ? normal_price.price_amount : normal_price.price_type === 'free';
  }

  const isEndTimeSetup= () => {
    return end_time.end_type === 'end_at' ? end_time.end_time_date_part : end_time.end_type === 'never';
  }

  const isQuantitySetup = () => {
    return quantity.quantity_type === 'limited' ? quantity.quantity_value : quantity.quantity_type === 'unlimited';
  }

  const isReadyForPreview = () => {
    return selected_online_service && isNormalPriceSetup() && isHeaderSetup() && isContentSetup() && isStaffSetup()
  }

  const isPriceReady = () => {
    return !(!price ||
      (!price.price_types.includes("one_time") && !price.price_types.includes("multiple_times") &&
        !price.price_types.includes("month") && !price.price_types.includes("year")) ||
      (price.price_types.includes("one_time") && !price.price_amounts?.one_time?.amount) ||
      (price.price_types.includes("multiple_times") && (!price.price_amounts?.multiple_times?.amount || !price.price_amounts?.multiple_times?.times)) ||
      (price.price_types.includes("month") && !price.price_amounts?.month?.amount) ||
      (price.price_types.includes("year") && !price.price_amounts?.year?.amount) ||
      (price.price_amounts?.one_time?.amount && price.price_amounts.one_time.amount < 100) ||
      (price.price_amounts?.multiple_times?.amount && price.price_amounts.multiple_times.amount < 100)
    )
  }

  return (
    <GlobalContext.Provider value={{
      props,
      ...hook_form_methods,
      ...state.sales_creation_states,
      dispatch,
      createSalesOnlineServicePage,
      createDraftSalesOnlineServicePage,
      isNormalPriceSetup,
      isEndTimeSetup,
      isQuantitySetup,
      isHeaderSetup,
      isContentSetup,
      isStaffSetup,
      isReadyForPreview,
      isPriceReady
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
