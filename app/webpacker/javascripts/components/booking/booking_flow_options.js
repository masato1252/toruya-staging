"use strict";

import React from "react";

const BookingFlowOptions = ({set_booking_reservation_form_values, booking_reservation_form_values, i18n}) => {
  const { flow_label, date_flow_first, option_flow_first } = i18n

  const isFlowSelected = () => {
    const { booking_option_id, booking_date, booking_at } = booking_reservation_form_values;

    return booking_option_id || (booking_date && booking_at)
  }

  if (isFlowSelected()) return <></>;

  return (
    <div>
      <div className="regular-customer-options">
        <h4>
          {flow_label}
        </h4>
        <div className="radios">
          <div className="radio">
            <label>
              <input name="booking_reservation_form[booking_flow]" type="radio" value="booking_date_first"
                checked={booking_reservation_form_values.booking_flow === "booking_date_first"}
                onChange={() => {
                  set_booking_reservation_form_values(prev => ({...prev, booking_flow: "booking_date_first"}))
                }}
              />
              {date_flow_first}
            </label>
          </div>
          <div className="radio">
            <label>
              <input name="booking_reservation_form[booking_flow]" type="radio" value="booking_option_first"
                checked={booking_reservation_form_values.booking_flow === "booking_option_first"}
                onChange={() => {
                  set_booking_reservation_form_values(prev => ({...prev, booking_flow: "booking_option_first"}))
                }}
              />
              {option_flow_first}
            </label>
          </div>
        </div>
      </div>
    </div>
  )
}

export default BookingFlowOptions
