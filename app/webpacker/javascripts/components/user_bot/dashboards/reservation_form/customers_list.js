"use strict"

import React, { useContext } from "react";

import { GlobalContext } from "context/user_bots/reservation_form/global_state";
import CustomerElement from "user_bot/dashboards/customers_dashboard/customer_element";
import { ReservationServices }from "user_bot/api";

const ReservationCustomersList = () =>  {
  const { menu_staffs_list, staff_states, customers_list, dispatch, props, start_time_date_part, getValues, end_at, setProcessing, reservation_errors } = useContext(GlobalContext)
  const { i18n } = props
  const { customer_max_load_capability } = reservation_errors
  const { pending_state, accepted_state } = props.reservation_properties.reservation_staff_states

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

    const [error, response] = await ReservationServices.addCustomer({business_owner_id: props.business_owner_id, shop_id: props.reservation_form.shop.id, data: params})
    window.location = response.data.redirect_to;
    setProcessing(false)
  }

  const customers_number = () => customers_list.filter((customer) => customer.state === accepted_state || customer.state === pending_state ).length

  const warning_content = () => {
    if (customers_number() !== 0) {
      if (customers_number() > customer_max_load_capability) {
        return <span className="warning with-symbol">{i18n.overbooking}</span>
      }
      else if (customers_number() === customer_max_load_capability) {
        return <span className="warning with-symbol">{i18n.become_overbooking}</span>
      }
    }
  }

  return (
    <>
      <div className="field-header space-between">
        &nbsp;
        <span className="customers-seats-state">
          <span>{i18n.reserved}</span>
          <span className={`number ${customers_number() > customer_max_load_capability ? "warning" : ""}`}>{customers_number()}</span>
          <span>{i18n.number}/{i18n.full_seat}{customer_max_load_capability}{i18n.number}</span>
        </span>
      </div>

      <div className="customers-list">
        {customers_list.map((customer) => {
          return (
            <CustomerElement
              key={`customer-id-${customer.id}`}
              stateIcon={
                <span className={`customer-reservation-state ${customer.state}`}>
                  <i className="fa fa-user"></i>
                </span>
              }
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
            <i className="fa fa-plus" aria-hidden="true" ></i> <span>{i18n.add_customer_btn}</span>
          </button>
          {warning_content()}
        </div>
      </div>
    </>
  )
}

export default ReservationCustomersList;
