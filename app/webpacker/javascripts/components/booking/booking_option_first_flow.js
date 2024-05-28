"use strict";

import React from "react";

import BookingPageOption from "./booking_page_option";
import SelectedBookingOption from "./selected_booking_option";
import BookingCalendar from "./booking_calendar";
import BookingDateTime from "./booking_date_time";

const BookingOptionFirstFlow = ({booking_reservation_form_values, i18n, sorted_booking_options, booking_options_quota, selectBookingOption, timezone, selected_booking_option, resetFlowValues, calendar, fetchBookingTimes, setBookingTimeAt, resetValues }) => {
  const {
    booking_options,
    last_selected_option_id,
    booking_flow,
    booking_option_id,
    booking_at
  } = booking_reservation_form_values;
  const { please_select_a_menu } = i18n;

  if (booking_flow !== "booking_option_first") return <></>

  return (
    <>
      {!booking_option_id && (
        <div className="result-fields booking-options">
          <h4>
            {please_select_a_menu}
          </h4>
          {sorted_booking_options(booking_options, last_selected_option_id).map((booking_option_value) => {
            return <BookingPageOption
              key={`booking_options-${booking_option_value.id}`}
              booking_option_value={booking_option_value}
              last_selected_option_id={last_selected_option_id}
              selectBookingOptionCallback={selectBookingOption}
              ticket={booking_options_quota[booking_option_value.id]}
              i18n={i18n}
            />
          })}
        </div>
      )}

      {booking_option_id && (
        <>
          <SelectedBookingOption
            i18n={i18n}
            booking_reservation_form_values={booking_reservation_form_values}
            booking_option_value={selected_booking_option}
            timezone={timezone}
            resetValuesCallback={resetFlowValues}
            ticket={booking_options_quota[booking_option_id]}
          />
          <BookingCalendar
            i18n={i18n}
            booking_reservation_form_values={booking_reservation_form_values}
            ticket_expire_date={booking_options_quota[booking_option_id]?.expire_date}
            calendar={calendar}
            fetchBookingTimes={fetchBookingTimes}
            setBookingTimeAt={setBookingTimeAt}
          />
        </>
      )}

      {booking_at && (
        <div>
          <BookingDateTime
            i18n={i18n}
            booking_reservation_form_values={booking_reservation_form_values}
            timezone={timezone}
            resetValuesCallback={() => resetValues(["booking_date", "booking_at", "booking_times"])}
          />
        </div>
      )}
    </>
  )
}

export default BookingOptionFirstFlow
