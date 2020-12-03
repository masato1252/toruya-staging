"use strict";

import React from "react";

import { useGlobalContext } from "context/user_bots/bookings/global_state";
import BookingFlowStepIndicator from "./booking_flow_step_indicator";

const PriceSetupStep = ({next, step}) => {
  const { props, i18n, dispatch, new_booking_option_price, new_booking_option_tax_include } = useGlobalContext()

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
        {i18n.unit}
      </div>
      <div className="booking-tax-types">
        <label>
          <input
            type="radio" name="tax_include"
            checked={new_booking_option_tax_include == "true"}
            onChange={
              () =>
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "new_booking_option_tax_include",
                    value: "true"
                  }
                })
            }
          />
          {i18n.tax_include}
        </label>
        <label>
          <input type="radio" name="tax_include"
            checked={new_booking_option_tax_include == "false"}
            onChange={
              ()=>
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "new_booking_option_tax_include",
                    value: "false"
                  }
                })
            }
          />
          {i18n.tax_excluded}
        </label>
      </div>
      <div className="action-block">
        <button
          className="btn btn-yellow"
          onClick={next}>
          {i18n.sell_this_price}
        </button>
      </div>
    </div>
  )
}

export default PriceSetupStep
