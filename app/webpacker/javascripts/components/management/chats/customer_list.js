"use strict";

import React, { useContext, useEffect } from "react";
import { GlobalContext } from "context/chats/global_state";
import Customer from "./customer";

const CustomerList = () => {
  const { subscription, customers, selected_channel_id, getCustomers } = useContext(GlobalContext)
  const channel_customers = customers[selected_channel_id] || []

  useEffect(() => {
    getCustomers()
  }, [subscription, selected_channel_id])

  return (
    <>
      <div id="customer-box">
        {channel_customers.map((customer, index) => <Customer customer={customer} key={`${customer.id}-${index}`}/>)}
      </div>
      <div className="btn btn-yellow" onClick={() => getCustomers(channel_customers[channel_customers.length - 1]?.updated_at) }>
        MORE
      </div>
    </>
  )
}

export default CustomerList;
