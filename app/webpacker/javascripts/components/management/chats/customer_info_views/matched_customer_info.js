"use strict";

import React, { useContext } from "react";
import { GlobalContext } from "context/chats/global_state";

export default () => {
  const { selected_customer, dispatch, subscription }= useContext(GlobalContext)
  const { id, name, address }= selected_customer.shop_customer

  const disconnectCustomer = () => {
    dispatch({
      type: "DISCONNECT_CUSTOMER",
      payload: selected_customer
    })

    subscription.perform("disconnect_customer", {
      customer_id: selected_customer.id
    })
  }

  return (
    <>
      <div className="info">
        <p>
          {name}
        </p>
        <p>
          {address}
        </p>
      </div>
      <button className="btn btn-orange" onClick={disconnectCustomer} >
        Disconnect
      </button>
    </>
  )
}
