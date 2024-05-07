"use strict";

import React from "react";
import moment from 'moment-timezone';

import BookingPageOption from "./booking_page_option";

const SelectedBookingOption = ({i18n, booking_reservation_form_values, booking_option_value, timezone, resetValuesCallback, ticket}) => {
  const {
    booking_option_id,
    booking_date,
    booking_at,
    last_selected_option_id,
  } = booking_reservation_form_values
  const { please_select_a_menu, edit } = i18n;

  if (!booking_option_id) return;

  const selected_booking_option_content = (
    <div className="selected-booking-option" id="selected-booking-option">
      <i className="fa fa-check-circle"></i>
      <BookingPageOption
        key={`booking_options-${booking_option_id}`}
        booking_option_value={booking_option_value}
        last_selected_option_id={last_selected_option_id}
        ticket={ticket}
        i18n={i18n}
        booking_start_at={moment.tz(`${booking_date} ${booking_at}`, "YYYY-MM-DD HH:mm", timezone)}
      />
    </div>
  )

  if (resetValuesCallback) {
    return (
      <div>
        <h4>
          {please_select_a_menu}
          <a href="#" className="edit" onClick={resetValuesCallback}>{edit}</a>
        </h4>
        {selected_booking_option_content}
      </div>
    )
  }

  return selected_booking_option_content
}

export default SelectedBookingOption
