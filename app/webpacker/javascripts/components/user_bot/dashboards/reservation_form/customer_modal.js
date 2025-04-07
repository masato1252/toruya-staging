"use strict"

import React, { useContext } from "react";

import { GlobalContext } from "context/user_bots/reservation_form/global_state";

const CustomerModal = () => {
  const { selected_customer, customers_list, dispatch, props } = useContext(GlobalContext)
  const {
    pend,
    accept_customer,
    customer_cancel,
  } = props.i18n;

  const {
    is_editable,
    current_staff_name,
    reservation_staff_states: {
      pending_state,
      accepted_state,
    }
  } = props.reservation_properties

  const is_selected_customer_approved = () => {
    const {
      accepted_state,
    } = props.reservation_properties.reservation_staff_states;

    return selected_customer.state === accepted_state;
  }

  const selected_customer_index = () => {
    return customers_list.findIndex((customer_item) => String(customer_item.customer_id) === String(selected_customer.customer_id))
  }

  const handleToggleCustomerState = (event) => {
    event.preventDefault();

    if (!is_editable) return

    let new_customer_list = [...customers_list]
    new_customer_list[selected_customer_index()]["state"] = is_selected_customer_approved() ? pending_state : accepted_state

    dispatch({
      type: "UPDATE_CUSTOMERS_LIST",
      payload: new_customer_list
    })

    $("#customer-modal").modal("hide")
  }

  const handleCustomerDelete = (event) => {
    if (!is_editable) return

    event.preventDefault();

    let new_customer_list = [...customers_list]

    if (selected_customer.binding) {
      new_customer_list[selected_customer_index()]["state"] = "canceled"
    }
    else {
      new_customer_list.splice(selected_customer_index(), 1)
    }

    dispatch({
      type: "UPDATE_CUSTOMERS_LIST",
      payload: new_customer_list
    })

    $("#customer-modal").modal("hide")
  }

  const approved = () => selected_customer && is_selected_customer_approved()

  return (
    <div className="modal fade" id="customer-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">×</span></button>
            <h4 className="modal-title">
              <span className={`reservation-state ${selected_customer && selected_customer.state}`}>
                  {selected_customer && selected_customer.state === "pending"
                    ? props.i18n.pending_state
                    : selected_customer && selected_customer.state === "canceled"
                      ? props.i18n.canceled
                      : props.i18n.accepted_state}
               </span>
               <span>{selected_customer && selected_customer.label}</span>
            </h4>
          </div>

          <div className="modal-body">
            <div dangerouslySetInnerHTML={{ __html: selected_customer && selected_customer.booking_price }} />
            <div dangerouslySetInnerHTML={{ __html: selected_customer && selected_customer.booking_customer_info_changed }} />
            { selected_customer && selected_customer.booking_from ? (
              <div dangerouslySetInnerHTML={{ __html: selected_customer && selected_customer.booking_from }} />
            ) :(
              <div className="booking-from reservation-info-row">
                <i className="fa fa-clock"></i>
                {current_staff_name}
              </div>
            )}
          </div>

          <div className="modal-footer">
            <dl>
              <dd>
                <button
                  className={`btn ${approved() ? "btn-gray" : "btn-tarco"} ${is_editable ? "" : "disabled"}`}
                  onClick={handleToggleCustomerState}>
                  {approved() ? pend : accept_customer}
                </button>
                {selected_customer && selected_customer.state !== "canceled" && (
                  <button
                    className={`btn btn-orange ${is_editable ? "" : "disabled"}`}
                    onClick={handleCustomerDelete}>
                    {customer_cancel}
                  </button>
                )}
              </dd>
            </dl>
          </div>
        </div>
      </div>
    </div>
  )
}

export default CustomerModal
