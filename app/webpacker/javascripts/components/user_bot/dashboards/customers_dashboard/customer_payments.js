"use strict"

import React, { useEffect } from "react";
import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import CustomerBasicInfo from "./customer_basic_info";
import CustomerNav from "./customer_nav";

import { CustomerServices } from "user_bot/api"

const PaymentCell = ({payment}) => {
  return (
    <>
      <div className={`state ${payment.state}`}></div>
      <dd className="date">{payment.month_date}</dd>
      <div className="time">
        <div className="start-time">
          {payment.time}
        </div>
      </div>
      <div className="content">
        {payment.product_name}
      </div>
      <div className="extra">
        {payment.amount}
      </div>
    </>
  )
}

const UserBotCustomerPayments = () =>{
  const { selected_customer, payments, dispatch, props, updateCustomer } = useGlobalContext()
  let previousYear;
  let divider;

  const fetchPayments = async () => {
    const [error, response] = await CustomerServices.payments({ user_id: props.super_user_id, customer_id: selected_customer.id })

    dispatch({
      type: "ASSIGN_CUSTOMER_PAYMENTS",
      payload: {
        payments: response?.data?.payments
      }
    })
  }

  useEffect(() => {
    fetchPayments()
  }, [selected_customer?.id])

  return (
    <div className="customer-view">
      <CustomerBasicInfo />
      <CustomerNav />
      <div className="events">
      {payments.map((payment) => {
        let divider = null;

        if (payment.year != previousYear) {
          previousYear = payment.year;
          divider = (
            <div className="event" key={`year-${payment.year}`}>
              <div className="cell"></div>
              <div className="cell"></div>
              <div className="year">
                {payment.year}
              </div>
              <div className="cell"></div>
              <div className="cell"></div>
            </div>
          )
        }

        return (
          <React.Fragment key={`payment-${payment.id}`}>
            {divider}
            {
              payment.state === "completed" ? (
                <div className="event"
                  data-controller="modal"
                  data-modal-target="#dummyModal"
                  data-action="click->modal#popup"
                  data-modal-path={Routes.refund_modal_lines_user_bot_customer_payment_path(payment.id, { from: "customer_dashboard", customer_id: selected_customer.id })} >
                  <PaymentCell payment={payment} />
                </div>
              ) : (
                <div className="event">
                  <PaymentCell payment={payment} />
                </div>
              )
            }
          </React.Fragment>
        )
      })}
      </div>
    </div>
  )
}

export default UserBotCustomerPayments;
