"use strict";

import React, { useContext } from "react";

import { GlobalContext } from "context/chats/global_state";
import MatchedCustomerInfo from "./customer_info_views/matched_customer_info";
import UnmatchedCustomerInfo from "./customer_info_views/unmatched_customer_info";

export default () => {
  const { selected_customer } = useContext(GlobalContext)

  if (selected_customer.id && selected_customer.shop_customer) {
    return (
      <div id="customer-info-box">
        <MatchedCustomerInfo />
      </div>
    )
  }
  else if (selected_customer.id) {
    return (
      <div id="customer-info-box">
        <UnmatchedCustomerInfo />
      </div>
    )
  }
  else {
    return (
      <div id="customer-info-box">
        unselected customer
      </div>
    )
  }
}
