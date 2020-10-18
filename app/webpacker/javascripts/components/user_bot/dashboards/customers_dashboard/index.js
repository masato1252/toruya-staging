"use strict"

import React, { useState, useContext, useEffect } from "react";
import UserBotCustomersList from "./customers_list"
import UserBotCustomerInfoView from "./customer_info_view"
import UserBotCustomerReservations from "./customer_reservations"
import UserBotCustomerMessages from "./customer_messages"
import { GlobalProvider, GlobalContext } from "context/user_bots/customers_dashboard/global_state"

const DashboardView = () => {
  const { view, props, dispatch, customers } = useContext(GlobalContext)

  useEffect(() => {
    if (props.customer?.id && customers.length) {
      dispatch({
        type: "SELECT_CUSTOMER",
        payload: {
          customer: customers.find(customer => customer.id == props.customer.id)
        }
      })

      dispatch({
        type: "CHANGE_VIEW",
        payload: {
          view: "customer_reservations"
        }
      })
    }
  }, [customers.length])

  switch (view) {
    case "list":
      return <UserBotCustomersList />
    case "customer_info_view":
      return <UserBotCustomerInfoView />
    case "customer_reservations":
      return <UserBotCustomerReservations />
    case "customer_messages":
      return <UserBotCustomerMessages />
    default:
      return <UserBotCustomersList />
  }
}

const UserBotCustomersDashboard = ({props}) => {
  return (
    <GlobalProvider props={props}>
      <DashboardView />
    </GlobalProvider>
  )
}

export default UserBotCustomersDashboard;
