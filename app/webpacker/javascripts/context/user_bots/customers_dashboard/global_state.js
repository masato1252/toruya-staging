import React, { createContext, useReducer, useRef, useMemo, useContext } from "react";

import combineReducer from "context/combine_reducer";
import customerReducer from "context/user_bots/customers_dashboard/customer_reducer";
import appReducer from "context/user_bots/customers_dashboard/app_reducer";
import notificationReducer from "context/notification_reducer";
import { useHistory } from "react-router-dom";

import { CustomerServices } from "user_bot/api";

export const GlobalContext = createContext()

export const useGlobalContext = () => {
  return useContext(GlobalContext)
}

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
      { customer_states: { total_customers_number: props.total_customers_number }},
      { notification_states: { notification_messages: props.notification_messages }}
    )
  }, [])
  console.log("initialValue", initialValue)

  const [state, dispatch] = useReducer(reducers, initialValue)
  const { customers, query_type, filter_pattern_number } = state.customer_states
  const last_updated_customer = customers[customers.length - 1]

  // state = {
  //   notification_states: [],
  //   app_states: {...},
  //   customer_states: {...},
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

  const updateCustomer = async (customer_id) => {
    const [error, response] = await CustomerServices.details(props.super_user_id, customer_id)

    dispatch({
      type: "UPDATE_CUSTOMER",
      payload: {
        customer: response.data.customer
      }
    })
  }

  const deleteCustomer = async (customer_id) => {
    const [error, response] = await CustomerServices.delete(props.super_user_id, customer_id)

    dispatch({
      type: "DELETE_CUSTOMER",
      payload: {
        customer_id: customer_id
      }
    })

    dispatch({
      type: "CHANGE_VIEW",
      payload: { view: "customers_list" }
    })
  }

  const recentCustomers = async () => {
    const [error, response] = await CustomerServices.recent(
      props.super_user_id,
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
        user_id: props.super_user_id,
        pattern_number: new_filter_pattern_number || filter_pattern_number
      })
    }
    else {
      currentPageRef.current += 1;

      [error, response] = await CustomerServices.filter({
        user_id: props.super_user_id,
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
        user_id: props.super_user_id,
        keyword: keywordRef.current
      })
    }
    else {
      currentPageRef.current += 1;

      [error, response] = await CustomerServices.search({
        user_id: props.super_user_id,
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

  const selectCustomer = (customer) => {
    dispatch({
      type: "SELECT_CUSTOMER",
      payload: { customer }
    })

    dispatch({
      type: "CHANGE_VIEW",
      payload: { view: "customer_reservations" }
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
      updateCustomer,
      searchCustomers,
      filterCustomers,
      selectCustomer,
      deleteCustomer
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
