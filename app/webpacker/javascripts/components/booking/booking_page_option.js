"use strict";

import React from "react";

const BookingPageOption = ({ booking_option_value, selectBookingOptionCallback, i18n }) => {
  const { open_details, close_details, booking_option_required_time, minute } = i18n;

  return (
    <div className="result-field">
      <div className="booking-option-field" data-controller="collapse" data-collapse-status="closed">
        <div className="booking-option-info" onClick={() => selectBookingOptionCallback(booking_option_value.id)}>
          <div className="booking-option-name">
            <b>
              {booking_option_value.label}
            </b>
          </div>

          {`${booking_option_required_time}${booking_option_value.minutes}${minute}`}
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
