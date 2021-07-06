"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

import { useGlobalContext } from "context/user_bots/bookings/global_state";
import BookingFlowStepIndicator from "./booking_flow_step_indicator";

const PriceSetupStep = ({next, step}) => {
  const { props, i18n, dispatch, new_booking_option_price } = useGlobalContext()

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
      </div>
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
