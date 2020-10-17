"use strict"

import React, { useContext } from "react";

import { GlobalContext } from "context/user_bots/reservation_form/global_state";
import CustomerElement from "user_bot/dashboards/customers_dashboard/customer_element";
import { ReservationServices }from "user_bot/api";

const ReservationCustomersList = () =>  {
  const { menu_staffs_list, staff_states, customers_list, dispatch, props, start_time_date_part, getValues, end_at, setProcessing } = useContext(GlobalContext)

  const addCustomer = async () => {
    setProcessing(true)
    const params = _.merge(
      getValues(),
      {
        reservation_id: props.reservation_form.reservation_id,
        end_time_date_part: start_time_date_part,
        end_time_time_part: end_at()?.format("HH:mm"),
        menu_staffs_list,
        staff_states,
        customers_list
      }
    )

    const [error, response] = await ReservationServices.addCustomer({shop_id: props.reservation_form.shop.id, data: params})
    window.location = response.data.redirect_to;
    setProcessing(false)
  }

  return (
    <div className="customers-list">
      {customers_list.map((customer) => {
        return (
          <CustomerElement
            stateIcon={
              <span className={`customer-reservation-state ${customer.state}`}>
                <i className="fa fa-user"></i>
              </span>
            }
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

      <div
        className="add-menu-block"
        onClick={addCustomer}>
        <button className="btn btn-yellow">
          <i className="fa fa-plus" aria-hidden="true" ></i>
          {props.i18n.add_customer_btn}
        </button>
      </div>
    </div>
  )
}

export default ReservationCustomersList;
