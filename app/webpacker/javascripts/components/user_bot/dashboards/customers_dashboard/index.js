"use strict"

import React, { useContext } from "react";
import { TopNavigationBar, BottomNavigationBar } from "shared/components"
import UserBotCustomersList from "./customers_list"
import CustomerSearchBar from "./customer_search_bar"

import { GlobalProvider, GlobalContext } from "context/user_bots/customers_dashboard/global_state"

const BottomBar = () => {
  const { customers } = useContext(GlobalContext)

  return (
    <BottomNavigationBar klassName="center">
      <span>{customers.length}</span>
    </BottomNavigationBar>
  )
}

const UserBotCustomersDashboard = ({props}) => {

  return (
    <GlobalProvider>
      <TopNavigationBar
        leading={<i className="fa fa-angle-left fa-2x"></i>}
        title={"title"}
      />
      <CustomerSearchBar />
      <UserBotCustomersList />
      <BottomBar />
    </GlobalProvider>
  )
}

export default UserBotCustomersDashboard;
