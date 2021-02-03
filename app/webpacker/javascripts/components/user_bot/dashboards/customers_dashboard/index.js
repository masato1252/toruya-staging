"use strict"

import React, { useState, useContext, useEffect } from "react";
import UserBotCustomersList from "./customers_list"
import UserBotCustomerInfoView from "./customer_info_view"
import UserBotCustomerInfoForm from "./customer_info_form"
import UserBotCustomerReservations from "./customer_reservations"
import UserBotCustomerMessages from "./customer_messages"
import { BrowserRouter as Router } from "react-router-dom";
import { GlobalProvider, GlobalContext } from "context/user_bots/customers_dashboard/global_state"

const DashboardView = () => {
  const { view, props, dispatch, customers } = useContext(GlobalContext)

  useEffect(() => {
    if (props.customer?.id) {
      dispatch({
        type: "SELECT_CUSTOMER",
        payload: {
          customer: props.customer
        }
      })

      dispatch({
        type: "CHANGE_VIEW",
        payload: {
          view: props.target_view || "customer_info_view"
        }
      })
    }
  }, [])

  switch (view) {
    case "customer_info_view":
      return <UserBotCustomerInfoView />
    case "customer_reservations":
      return <UserBotCustomerReservations />
    case "customer_info_form":
      return <UserBotCustomerInfoForm />
    case "customer_messages":
      return <UserBotCustomerMessages />
    default:
      return <></>
  }
}

const UserBotCustomersDashboard = ({props}) => {
  return (
    <GlobalProvider props={props}>
      <Router>
        <DashboardView />
        <UserBotCustomersList />
      </Router>
    </GlobalProvider>
  )
}

export default UserBotCustomersDashboard;
