"use strict";

import React from "react";

import BookingPageOption from "./booking_page_option";
import SelectedBookingOption from "./selected_booking_option";
import BookingCalendar from "./booking_calendar";
import BookingDateTime from "./booking_date_time";

const BookingOptionFirstFlow = ({
  booking_reservation_form_values,
  i18n,
  sorted_booking_options,
  booking_options_quota,
  selectBookingOption,
  unselectBookingOption,
  timezone,
  selected_booking_options,
  resetFlowValues,
  calendar,
  fetchBookingTimes,
  setBookingTimeAt,
  resetValues,
  set_booking_reservation_form_values,
  scrollToTarget
}) => {
  const {
    booking_options,
    last_selected_option_ids,
    booking_flow,
    booking_option_ids,
    booking_at,
    booking_option_selected_flow_done,
    staff_selection_done,
    staff_selection_required,
  } = booking_reservation_form_values;
  const { please_select_a_menu, edit } = i18n;

  if (booking_flow !== "booking_option_first") return <></>

  return (
    <>
      {
        booking_option_selected_flow_done && (
        <div className="result-fields booking-options">
            <h4 className="p-0">{I18n.t("booking_page.selected_booking_options")} </h4>
            <h4 className="pb-3">
              <a href="#" className="edit" onClick={resetFlowValues}>{edit}</a>
            </h4>
            {selected_booking_options?.map(booking_option_value => (
              <SelectedBookingOption
                key={`selected-booking-option-${booking_option_value.id}`}
                i18n={i18n}
                booking_reservation_form_values={booking_reservation_form_values}
                booking_option_value={booking_option_value}
                timezone={timezone}
                resetValuesCallback={resetFlowValues}
                ticket={booking_options_quota[booking_option_value.id]}
              />
            ))}
          </div>
        )
      }

      {!booking_option_selected_flow_done && (
        <div className="result-fields booking-options">
          {staff_selection_required && staff_selection_done &&  (
            <div>
              {resetValues && <a href="#" className="edit" onClick={() => resetValues(["staff_selection_done"])}>{edit}</a>}
            </div>
          )}
          <h4>
            {please_select_a_menu}
          </h4>
          {sorted_booking_options(booking_options, last_selected_option_ids)
            .map((booking_option_value) => {
              if (booking_option_ids?.includes(booking_option_value.id)) {
                return (
                  <SelectedBookingOption
                    key={`selected-booking-option-${booking_option_value.id}`}
                    i18n={i18n}
                    booking_reservation_form_values={booking_reservation_form_values}
                    booking_option_value={booking_option_value}
                    timezone={timezone}
                    resetValuesCallback={resetFlowValues}
                    ticket={booking_options_quota[booking_option_value.id]}
                    unselectBookingOption={unselectBookingOption}
                    selected_booking_option_ids={booking_option_ids}
                  />
                )
              }
              else {
                return (
                  <BookingPageOption
                    key={`booking_options-${booking_option_value.id}`}
                    booking_option_value={booking_option_value}
                    last_selected_option_ids={last_selected_option_ids}
                    selectBookingOptionCallback={selectBookingOption}
                    ticket={booking_options_quota[booking_option_value.id]}
                    selected_booking_option_ids={booking_option_ids}
                    i18n={i18n}
                  />
                )
              }
            })}
        </div>
      )}

      {booking_option_ids.length > 0 && !booking_option_selected_flow_done && (
        <div className="margin-around centerize">
          <a
            className="btn btn-primary"
            onClick={() => {
              set_booking_reservation_form_values(prev => ({
                ...prev,
                booking_option_selected_flow_done: true
              }))
            }}
          >
            {I18n.t("booking_page.confirm_booking_option")}
          </a>
        </div>
      )}


      {booking_option_selected_flow_done && (
        <BookingCalendar
          i18n={i18n}
          booking_reservation_form_values={booking_reservation_form_values}
          ticket_expire_date={booking_option_ids.map(id => booking_options_quota[id]?.expire_date).sort()[0]}
          calendar={calendar}
          fetchBookingTimes={fetchBookingTimes}
          setBookingTimeAt={setBookingTimeAt}
          scrollToTarget={scrollToTarget}
        />
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