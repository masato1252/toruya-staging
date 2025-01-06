"use strict";

import React from "react";
import moment from 'moment-timezone';

import BookingPageOption from "./booking_page_option";

const SelectedBookingOption = ({
  i18n,
  booking_reservation_form_values,
  booking_option_value,
  timezone,
  resetValuesCallback,
  ticket,
  unselectBookingOption,
  selected_booking_option_ids
}) => {
  const {
    booking_option_ids,
    booking_date,
    booking_at,
    last_selected_option_ids,
  } = booking_reservation_form_values

  if (!booking_option_ids.length) return <></>;

  const selected_booking_option_content = (
    <div className="selected-booking-option" id="selected-booking-option">
      <i className="fa fa-check-circle"></i>
      <BookingPageOption
        key={`booking_options-${booking_option_value.id}`}
        booking_option_value={booking_option_value}
        last_selected_option_ids={last_selected_option_ids}
        ticket={ticket}
        i18n={i18n}
        booking_start_at={booking_date && booking_at ? moment.tz(`${booking_date} ${booking_at}`, "YYYY-MM-DD HH:mm", timezone) : null}
        unselectBookingOption={unselectBookingOption}
        selected_booking_option_ids={selected_booking_option_ids}
      />
    </div>
  )

  if (resetValuesCallback) {
    return (
      <div>
        {selected_booking_option_content}
      </div>
    )
  }

  return selected_booking_option_content
}

export default SelectedBookingOption
