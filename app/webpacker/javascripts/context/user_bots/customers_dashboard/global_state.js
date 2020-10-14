import React, { createContext, useReducer, useRef } from "react";

import combineReducer from "context/combine_reducer";
import customerReducer from "context/user_bots/customers_dashboard/customer_reducer";

import { CustomerServices } from "user_bot/api";

export const GlobalContext = createContext()

const reducers = combineReducer({
  customer_states: customerReducer
})

export const GlobalProvider = ({ children }) => {
  const keywordRef = useRef()
  let currentPageRef = useRef(0)
  const [state, dispatch] = useReducer(reducers, reducers())
  const { customers, customer_query_type } = state.customer_states
  const last_updated_customer = customers[customers.length - 1]

  // state = {
  //   customer_states: {...}
  // }
  const getCustomers = () => {
    switch (customer_query_type) {
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

  const searchCustomers = async (keyword = null) => {
    let firstQuery = false
    let error, response

    if (keyword != null) {
      if (keywordRef.current != keyword || customer_query_type != "search") firstQuery = true
      if (keywordRef.current != keyword) {
        keywordRef.current = keyword
      }
    }

    if (firstQuery) {
      currentPageRef.current = 1;

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
        customer_query_type: "search",
        initial: firstQuery
      }
    })
  }

  return (
    <GlobalContext.Provider value={{
      ...state.customer_states,
      dispatch,
      getCustomers,
      searchCustomers
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
