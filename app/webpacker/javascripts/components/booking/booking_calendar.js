"use strict";

import React, { useLayoutEffect } from "react";
import { SlideDown } from 'react-slidedown';

import Calendar from "shared/calendar/calendar";

const BookingTimes = ({booking_reservation_form_values, i18n, setBookingTimeAt}) => {
  const {
    booking_times,
    booking_date,
    booking_at,
    is_fetching_booking_time,
  } = booking_reservation_form_values;

  const {
    no_available_booking_times
  } = i18n;

  if (is_fetching_booking_time) {
    return (
      <div className="spinner-loading">
        <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
      </div>
    )
  }
  else if (booking_times && Object.keys(booking_times).length) {
    return (
      <div>
        {Object.keys(booking_times).map((time, i) => (
          <div
            className={`time-interval ${time == booking_at ? "selected-time-item" : ""}`}
            key={`booking-time-${time}`}
            onClick={() => setBookingTimeAt(time)}>
            {time}~
          </div>)
        )}
      </div>
    )
  } else if (booking_date) {
    return <div className="warning">{no_available_booking_times}</div>
  }
  else {
    return <></>
  }
}

const BookingCalendar = ({booking_reservation_form_values, i18n, calendar, fetchBookingTimes, setBookingTimeAt, ticket_expire_date, scrollToTarget}) => {
  const {
    booking_date,
    booking_at,
    booking_option_ids,
  } = booking_reservation_form_values;

  const {
    booking_dates_calendar_hint,
    booking_dates_working_date,
    booking_dates_available_booking_date,
    date,
    start_time,
  } = i18n;

  useLayoutEffect(() => {
    setTimeout(() => {
      scrollToTarget("footer")
    }, 2000)
  }, [])


  return (
    <SlideDown className={'calendar-slidedown'}>
      {
        !booking_date || !booking_at ? (
          <div className="booking-calendar">
            <h4>
              {date}
            </h4>
            {booking_dates_calendar_hint}
            <Calendar
              {...calendar}
              skip_default_date={true}
              dateSelectedCallback={fetchBookingTimes}
              scheduleParams={{
                staff_id: booking_reservation_form_values.selected_staff_id,
                booking_option_ids: booking_option_ids,
                customer_id: booking_reservation_form_values?.customer_info?.id
              }}
            />
            <div className="demo-days">
              <div className="demo-day day booking-available"></div>
              {booking_dates_available_booking_date}
              <div className="demo-day day workDay"></div>
              {booking_dates_working_date}
            </div>
            <h4 id="times_header">
              {booking_date && start_time}
            </h4>
            <BookingTimes
              booking_reservation_form_values={booking_reservation_form_values}
              i18n={i18n}
              setBookingTimeAt={setBookingTimeAt}
            />
          </div>
        ) : null
      }
    </SlideDown>
  )
}

export default BookingCalendar
