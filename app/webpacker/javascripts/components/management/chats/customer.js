"use strict";

import React, { useContext } from "react";
import { GlobalContext } from "context/chats/global_state";

export default ({ customer }) => {
  const { selected_customer_id, dispatch }= useContext(GlobalContext)

  return (
    <div
      className={`customer ${customer.id === selected_customer_id ? "selected" : ""}`}
      onClick={() => dispatch({
          type: "SELECT_CUSTOMER",
          payload: customer.id
        })
      }
    >
      { customer.name }
    </div>
  )
}
