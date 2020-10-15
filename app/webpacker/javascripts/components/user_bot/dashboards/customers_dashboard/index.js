"use strict"

import React, { useState, useContext } from "react";
import UserBotCustomersList from "./customers_list"
import UserBotCustomerInfoView from "./customer_info_view"
import { GlobalProvider, GlobalContext } from "context/user_bots/customers_dashboard/global_state"


const DashboardView = () => {
  const { view } = useContext(GlobalContext)
  let customerView

  switch (view) {
    case "list":
      customerView = <UserBotCustomersList />
      break;
    case "customer_info_view":
      customerView = <UserBotCustomerInfoView />
      break;
    default:
      customerView = <UserBotCustomersList />
      break;
  }

  return customerView;
}

const UserBotCustomersDashboard = ({props}) => {
  return (
    <GlobalProvider props={props}>
      <DashboardView />
    </GlobalProvider>
  )
}

export default UserBotCustomersDashboard;
