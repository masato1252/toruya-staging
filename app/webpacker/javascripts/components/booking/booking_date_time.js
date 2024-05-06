"use strict";

import React from "react";
import moment from 'moment-timezone';

const BookingDateTime = ({ booking_reservation_form_values, resetValuesCallback, i18n, timezone}) => {
  const {
    booking_date,
    booking_at,
  } = booking_reservation_form_values
  if (!(booking_date && booking_at)) return;

  const { edit, time_from } = i18n;

  return (
    <div className="selected-booking-datetime" id="selected-booking-datetime">
      <i className="fa fa-calendar"></i>
      {moment.tz(`${booking_date} ${booking_at}`, "YYYY-MM-DD HH:mm", timezone).format("llll")} {time_from}
      {resetValuesCallback && <a href="#" className="edit" onClick={resetValuesCallback}>{edit}</a>}
    </div>
  )
}

export default BookingDateTime
