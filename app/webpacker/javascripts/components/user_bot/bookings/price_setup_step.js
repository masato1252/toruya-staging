"use strict";

import React, { useEffect } from "react";
import I18n from 'i18n-js/index.js.erb';

import { useGlobalContext } from "context/user_bots/bookings/global_state";
import BookingFlowStepIndicator from "./booking_flow_step_indicator";
import { ErrorMessage, TicketPriceDesc } from "shared/components";

const PriceSetupStep = ({next, step}) => {
  const { props, i18n, dispatch, new_booking_option_price, price_type, ticket_quota, ticket_expire_month } = useGlobalContext()

  useEffect(() => {
    let quota = 1
    if (price_type == "ticket" && (ticket_quota == '' || ticket_quota < 2 )) quota = 2;

    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "ticket_quota",
        value: quota
      }
    })
  }, [price_type])

  return (
    <div className="booking-creation-flow centerize form">
      <BookingFlowStepIndicator step={step} i18n={i18n} />
      <h3 className="header centerize">{i18n.how_much_of_this_price}</h3>
      <div>
        <input
          type="tel"
          value={new_booking_option_price || ""}
          placeholder={i18n.enter_price}
          onChange={
          (event) => {
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "new_booking_option_price",
                value: event.target.value
              }
            })
          }
        } />
        {i18n.unit}({I18n.t("common.tax_included")})
        {price_type == "ticket" && new_booking_option_price && new_booking_option_price > 50000 &&
          <div className="warning">{I18n.t("settings.booking_option.form.form_errors.ticket_max_price_limit")}</div>}
        {new_booking_option_price && new_booking_option_price < 100 &&
          <div className="warning">{I18n.t("errors.selling_price_too_low")}</div>}
      </div>
      <div className="my-2">
        <label className="mx-2">
          <input
            name="price_type"
            type="radio"
            value="regular"
            checked={price_type === "regular"}
            onChange={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "price_type",
                  value: "regular"
                }
              })
            }}
          />
          {I18n.t("common.regular_price")}
        </label>
        <label>
          <input
            name="price_type"
            type="radio"
            value="ticket"
            checked={price_type === "ticket"}
            onChange={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "price_type",
                  value: "ticket"
                }
              })
            }}
          />
          {I18n.t("common.ticket")}
        </label>
      </div>
      {price_type == "ticket" && (
        <>
          <h3 className="header centerize">{I18n.t("settings.booking_option.form.how_many_ticket_in_one_book")}</h3>
          <div>
            <div>
              <select
                name="ticket_quota"
                value={ticket_quota}
                onChange={(event) => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "ticket_quota",
                      value: event.target.value
                    }
                  })
                }}
              >
                {[2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
                  12, 13, 14, 15, 16, 17, 18, 19, 20].map((num) => <option key={`quota-$${num}`} value={num}>{num}</option>)}
              </select> {I18n.t("common.times")}
              <div>
                <TicketPriceDesc amount={new_booking_option_price} ticket_quota={ticket_quota} />
              </div>
            </div>
          </div>
          <h3 className="header centerize">{I18n.t("settings.booking_option.form.when_ticket_expire")}</h3>
          <div>
            <span>
              {I18n.t("settings.booking_option.form.from_purchase")}
              <select
                name="ticket_expire_month"
                value={ticket_expire_month}
                onChange={(event) => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "ticket_expire_month",
                      value: event.target.value
                    }
                  })
                }}
              >
                {[1, 2, 3, 4, 5, 6].map((num) => <option key={`month-$${num}`} value={num}>{num}</option>)}
              </select>
              {I18n.t("settings.booking_option.form.after_month")}
              {ticket_expire_month == 6 && <>（{I18n.t("settings.booking_option.form.max_ticket_date")}）</>}
            </span>
          </div>
          <div>
            <img src={props.ticket_expire_date_desc_path} className="w-full" />
          </div>
        </>
      )}
      <div className="action-block">
        <button
          className="btn btn-yellow"
          onClick={next}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default PriceSetupStep
