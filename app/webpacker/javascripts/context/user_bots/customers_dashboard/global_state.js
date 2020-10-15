import React, { createContext, useReducer, useRef, useMemo } from "react";

import combineReducer from "context/combine_reducer";
import customerReducer from "context/user_bots/customers_dashboard/customer_reducer";
import appReducer from "context/user_bots/customers_dashboard/app_reducer";
import notificationReducer from "context/notification_reducer";

import { CustomerServices } from "user_bot/api";

export const GlobalContext = createContext()

const reducers = combineReducer({
  notification_states: notificationReducer,
  app_states: appReducer,
  customer_states: customerReducer
})

export const GlobalProvider = ({ props, children }) => {
  const keywordRef = useRef()
  let currentPageRef = useRef(0)

  const initialValue = useMemo(() => {
    return _.merge(
      reducers(),
      { notification_states: { notification_messages: props.notification_messages }}
    )
  }, [])

  const [state, dispatch] = useReducer(reducers, initialValue)
  const { customers, query_type, filter_pattern_number } = state.customer_states
  const last_updated_customer = customers[customers.length - 1]

  // state = {
  //   customer_states: {...}
  // }
  const getCustomers = () => {
    switch (query_type) {
      case "recent":
        recentCustomers()
        break;
      case "filter":
        filterCustomers()
        break;
      case "search":
        searchCustomers()
        break;
    }
  }

  const recentCustomers = async () => {
    const [error, response] = await CustomerServices.recent(
      last_updated_customer?.id,
      last_updated_customer?.updatedAt
    )

    dispatch({
      type: "APPEND_CUSTOMERS",
      payload: {
        customers: response.data.customers,
        is_all_customers_loaded: response.data.customers.length === 0
      }
    })
  }

  const filterCustomers = async (new_filter_pattern_number = null) => {
    let firstQuery = false
    let error, response

    if (new_filter_pattern_number != null &&
      (filter_pattern_number != new_filter_pattern_number || query_type != "filter")) {
      await dispatch({ type: "RESET_CUSTOMERS" })

      firstQuery = true
      currentPageRef.current = 1;
    }

    if (firstQuery) {
      [error, response] = await CustomerServices.filter({
        pattern_number: new_filter_pattern_number || filter_pattern_number
      })
    }
    else {
      currentPageRef.current += 1;

      [error, response] = await CustomerServices.filter({
        page: currentPageRef.current,
        pattern_number: new_filter_pattern_number || filter_pattern_number
      })
    }

    dispatch({
      type: "APPEND_CUSTOMERS",
      payload: {
        customers: response.data.customers,
        is_all_customers_loaded: response.data.customers.length === 0,
        query_type: "filter",
        initial: firstQuery,
        filter_pattern_number: new_filter_pattern_number
      }
    })
  }

  const searchCustomers = async (keyword = null) => {
    let firstQuery = false
    let error, response

    if (keyword != null &&
      (keywordRef.current != keyword || query_type != "search"))  {
      await dispatch({ type: "RESET_CUSTOMERS" })

      firstQuery = true
      keywordRef.current = keyword
      currentPageRef.current = 1;
    }

    if (firstQuery) {
      [error, response] = await CustomerServices.search({
        keyword: keywordRef.current
      })
    }
    else {
      currentPageRef.current += 1;

      [error, response] = await CustomerServices.search({
        page: currentPageRef.current,
        keyword: keywordRef.current
      })
    }

    dispatch({
      type: "APPEND_CUSTOMERS",
      payload: {
        customers: response.data.customers,
        is_all_customers_loaded: response.data.customers.length === 0,
        query_type: "search",
        initial: firstQuery
      }
    })
  }

  return (
    <GlobalContext.Provider value={{
      props,
      ...state.notification_states,
      ...state.app_states,
      ...state.customer_states,
      dispatch,
      getCustomers,
      searchCustomers,
      filterCustomers
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
