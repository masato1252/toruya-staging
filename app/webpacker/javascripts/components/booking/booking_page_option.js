"use strict";

import React from "react";
import moment from 'moment-timezone';

const BookingPageOption = ({ booking_option_value, selectBookingOptionCallback, i18n, booking_start_at }) => {
  let option_content;
  const { open_details, close_details, booking_option_required_time, minute } = i18n;

  const handleOptionClick = (booking_option_id) => {
    if (selectBookingOptionCallback) {
      selectBookingOptionCallback(booking_option_id)
    }
  }

  if (selectBookingOptionCallback || !booking_start_at || !booking_start_at.isValid()) {
    option_content = `${booking_option_required_time}${booking_option_value.minutes}${minute}`;
  }
  else {
    booking_start_at = booking_start_at.add(booking_option_value.minutes, "minutes")
    option_content = `${booking_start_at.format("hh:mm")} ${i18n.booking_end_at}`
  }

  return (
    <div className="result-field">
      <div className="booking-option-field" data-controller="collapse" data-collapse-status="closed">
        <div className="booking-option-info" onClick={() => handleOptionClick(booking_option_value.id)}>
          <div className="booking-option-name">
            <b>
              {booking_option_value.label}
            </b>
          </div>

          {option_content}
        </div>

        <div className="booking-option-row">
          <span>
            {booking_option_value.price}
          </span>

          {booking_option_value.memo && booking_option_value.memo.length &&
            <span className="booking-option-details-toggler" data-action="click->collapse#toggle">
              <a className="toggler-link" data-target="collapse.openToggler">{close_details}<i className="fa fa-chevron-up" aria-hidden="true"></i></a>
              <a className="toggler-link" data-target="collapse.closeToggler">{open_details}<i className="fa fa-chevron-down" aria-hidden="true"></i></a>
            </span>
          }
        </div>
        <div className="booking-option-row" data-target="collapse.content">
          {booking_option_value.memo}
        </div>
      </div>
    </div>
  )
}

export default BookingPageOption
