"use strict";

import React from "react";
import _ from "lodash";

import BookingCalendar from "./booking_calendar";
import BookingPageOption from "./booking_page_option";
import BookingDateTime from "./booking_date_time";
import SelectedBookingOption from "./selected_booking_option";

const AvailableBookingOption = ({booking_reservation_form_values, i18n, sorted_booking_options, selectBookingOption, booking_options_quota }) => {
  const {
    booking_options,
    booking_at,
    booking_times,
    last_selected_option_id,
    booking_option_id
  } = booking_reservation_form_values;

  if (!booking_at) return;
  let available_booking_options;

  if (booking_times) {
    available_booking_options = _.filter(booking_options, (booking_option) => {
      return _.includes(booking_times[booking_at], booking_option.id)
    })
  }
  else {
    available_booking_options = _.filter(booking_options, (booking_option) => {
      return booking_option.id === booking_option_id
    })
  }

  return (
    <div className="result-fields booking-options">
      {sorted_booking_options(available_booking_options, last_selected_option_id).map((booking_option_value) => {
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
  )
};

const BookingDateFirstFlow = ({booking_reservation_form_values, i18n, calendar, fetchBookingTimes, setBookingTimeAt, timezone, resetValues, selected_booking_option, selectBookingOption, sorted_booking_options, booking_options_quota}) => {
  const { booking_flow, booking_at, booking_option_id } = booking_reservation_form_values;

  if (booking_flow !== "booking_date_first") return <></>

  return (
    <>
      <BookingCalendar
        i18n={i18n}
        booking_reservation_form_values={booking_reservation_form_values}
        calendar={calendar}
        fetchBookingTimes={fetchBookingTimes}
        setBookingTimeAt={setBookingTimeAt}
      />

      {booking_at && (
        <>
          <div>
            <BookingDateTime
              i18n={i18n}
              booking_reservation_form_values={booking_reservation_form_values}
              timezone={timezone}
              resetValuesCallback={() => resetValues(["booking_date", "booking_at", "booking_times"])}
            />
          </div>
          {!booking_option_id && (
            <AvailableBookingOption
              booking_reservation_form_values={booking_reservation_form_values}
              i18n={i18n}
              sorted_booking_options={sorted_booking_options}
              selectBookingOption={selectBookingOption}
              booking_options_quota={booking_options_quota}
            />
          )}
        </>
      )}
      {booking_option_id && (
        <>
          <SelectedBookingOption
            i18n={i18n}
            booking_reservation_form_values={booking_reservation_form_values}
            booking_option_value={selected_booking_option}
            ticket={booking_options_quota[booking_option_id]}
            timezone={timezone}
            resetValuesCallback={() => resetValues(["booking_option_id"])}
          />
        </>
      )}
    </>
  )
}

export default BookingDateFirstFlow;
