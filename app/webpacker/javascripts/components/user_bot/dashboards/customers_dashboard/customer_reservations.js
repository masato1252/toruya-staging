"use strict"

import React, { useEffect, useCallback } from "react";
import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import CustomerBasicInfo from "./customer_basic_info";
import CustomerNav from "./customer_nav";

import { CustomerServices } from "user_bot/api"

const UserBotCustomerReservations = () =>{
  const { selected_customer, reservations, dispatch, props, updateCustomer } = useGlobalContext()
  let previousYear;
  let divider;

  const customerDataChangedHandler = event => {
    updateCustomer(event.detail.customer_id)
  }

  useEffect(() => {
    window.addEventListener("customer:data-changed", customerDataChangedHandler);

    return () => {
      window.removeEventListener("customer:data-changed", customerDataChangedHandler)
    }
  }, [])

  const fetchReservations = async () => {
    const [error, response] = await CustomerServices.reservations({ user_id: props.super_user_id, customer_id: selected_customer.id })

    dispatch({
      type: "ASSIGN_CUSTOMER_CUSTOMERS",
      payload: {
        reservations: response?.data?.reservations
      }
    })
  }

  useEffect(() => {
    fetchReservations()
  }, [selected_customer?.id])

  return (
    <div className="customer-view">
      <CustomerBasicInfo />
      <CustomerNav />
      <div className="events">
      {reservations.map((reservation) => {
        let divider = null;

        if (reservation.year != previousYear) {
          previousYear = reservation.year;
          divider = (
            <div className="event" key={`year-${reservation.year}`}>
              <div className="cell">
              </div>
              <div className="cell"></div>
              <div className="year">
                {reservation.year}
              </div>
              <div className="cell"></div>
              <div className="cell"></div>
              <div className="cell"></div>
            </div>
          )
        }

        return (
          <React.Fragment
            key={`reservation-${reservation.id}`}
          >
            {divider}
            <div
              className="event"
              data-controller="modal"
              data-modal-target="#dummyModal"
              data-action="click->modal#popup"
              data-modal-path={Routes.lines_user_bot_shop_reservation_path(reservation.shopId, reservation.id, { from: "customer_dashboard", customer_id: selected_customer.id })} >
              <div className={`state ${reservation.state}`}></div>
              <dd className="date">{reservation.monthDate}</dd>
              <div className="time">
                <div className="start-time">
                  {reservation.startTime}
                </div>
                <div className="start-time">
                  {reservation.endTime}
                </div>
              </div>
              <div className="content">
                <div className="top">
                  {reservation.menu}
                </div>
              </div>
              <div className="info">
                {reservation.shop}
              </div>
              <div className="extra">
                {
                  reservation.withWarnings ? (
                    <span className="error-status warning"><i className="fa fa-check-circle"></i></span>
                  ) : null
                }
                {
                  reservation.deletedStaffs ? (
                    <span className="status danger"><i className="fa fa-exclamation-circle"></i></span>
                  ) : null
                }
              </div>
            </div>
          </React.Fragment>
        )
      })}
      </div>
    </div>
  )
}

export default UserBotCustomerReservations;
