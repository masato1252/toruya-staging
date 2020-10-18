"use strict"

import React, { useContext } from "react";
import { GlobalContext } from "context/user_bots/customers_dashboard/global_state";
import CustomerBasicInfo from "./customer_basic_info";
import CustomerNav from "./customer_nav";

const UserBotCustomerMessages = () => {
  return (
    <div className="customer-view">
      <CustomerBasicInfo />
      <CustomerNav />
      messages
    </div>
  )
}

export default UserBotCustomerMessages;
