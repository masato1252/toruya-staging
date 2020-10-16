"use strict"

import React, { useState } from "react";
import CustomerElement from "user_bot/dashboards/customers_dashboard/customer_element";

const ReservationCustomersList = ({props, customers_list, setCustomersList, setSelectedCustomer, setCustomerModalOpen}) =>  {
  return (
    <div className="customers-list">
      {customers_list.map((customer) => {
        return (
          <CustomerElement
            key={customer.id}
            customer={customer}
            onHandleClick={() => {
              setSelectedCustomer(customer)
              $("#customer-modal").modal("show")
            }}
          />
        )
      })}
    </div>
  )
}

export default ReservationCustomersList;
