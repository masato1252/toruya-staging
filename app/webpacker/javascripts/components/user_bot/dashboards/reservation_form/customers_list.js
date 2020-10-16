"use strict"

import React, { useContext } from "react";

import { GlobalContext } from "context/user_bots/reservation_form/global_state";
import CustomerElement from "user_bot/dashboards/customers_dashboard/customer_element";

const ReservationCustomersList = () =>  {
  const { customers_list, dispatch, props } = useContext(GlobalContext)

  return (
    <div className="customers-list">
      {customers_list.map((customer) => {
        return (
          <CustomerElement
            key={customer.id}
            customer={customer}
            onHandleClick={() => {
              dispatch({
                type: "SELECT_CUSTOMER",
                payload: customer
              })

              $("#customer-modal").modal("show")
            }}
          />
        )
      })}
    </div>
  )
}

export default ReservationCustomersList;
