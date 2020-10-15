"use strict"

import React, { useContext } from "react";
import { GlobalContext } from "context/user_bots/customers_dashboard/global_state";
import CustomerBasicInfo from "./customer_basic_info";

const UserBotCustomerInfoView = () =>{
  return (
    <div className="customer-view">
      <CustomerBasicInfo />
    </div>
  )
}

export default UserBotCustomerInfoView;
