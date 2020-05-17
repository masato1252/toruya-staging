"use strict";

import React, { useContext } from "react";
import { GlobalContext } from "context/chats/global_state";

import CustomerModeSwitch from "./customer_mode_switch";

export default ({ customer }) => {
  const { selected_customer_id, dispatch }= useContext(GlobalContext)

  return (
    <div className={`customer ${customer.id === selected_customer_id ? "selected" : ""}`} >
      <div
        onClick={() => dispatch({
          type: "SELECT_CUSTOMER",
          payload: customer
        })
        }
      >
        { customer.name } { customer.unread_message_count ? `(${customer.unread_message_count})` : "" }
      </div>
      <CustomerModeSwitch customer={customer} />
    </div>
  )
}
