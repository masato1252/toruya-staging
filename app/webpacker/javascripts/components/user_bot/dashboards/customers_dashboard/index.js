"use strict"

import React, { useState, useContext } from "react";
import UserBotCustomersList from "./customers_list"
import UserBotCustomerInfoView from "./customer_info_view"
import UserBotCustomerReservations from "./customer_reservations"
import UserBotCustomerMessages from "./customer_messages"
import { GlobalProvider, GlobalContext } from "context/user_bots/customers_dashboard/global_state"

const DashboardView = () => {
  const { view } = useContext(GlobalContext)

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
