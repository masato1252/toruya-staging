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
    const [error, response] = await CustomerServices.reservations({ business_owner_id: props.business_owner_id, customer_id: selected_customer.id })

    dispatch({
      type: "ASSIGN_CUSTOMER_RESERVATIONS",
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
            key={`reservation-${reservation.type}-${reservation.id}`}
          >
            {divider}
            <div
              className="event"
              data-controller="modal"
              data-modal-target="#dummyModal"
              data-action="click->modal#popup"
              data-modal-path={reservation.type === "Reservation" ? Routes.lines_user_bot_shop_reservation_path(reservation.userId, reservation.shopId, reservation.id, { from: "customer_dashboard", customer_id: selected_customer.id }) : Routes.lines_user_bot_online_service_customer_relation_path(reservation.userId, reservation.id, { from: "customer_dashboard", customer_id: selected_customer.id })} >
              <div className={`state ${reservation.reservation_customer_state}`}></div>
              <dd className="date">
                {reservation.monthDate}
              </dd>
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
                  {reservation.ticket_code && (
                    <>
                      <i className="fa fa-ticket-alt text-gray-500"></i> {reservation.ticket_code} ({reservation.nth_quota}/{reservation.total_quota}{I18n.t("common.times")})
                    </>
                  )}
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
