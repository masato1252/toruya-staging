"use strict";

import React from "react";
import Autolinker from 'autolinker';

import BookingFailedArea from "./booking_failed_area";

const BookingReservationButton = ({
  set_booking_reservation_form_values, booking_reservation_form_values, i18n, booking_page, payment_solution,
  isBookingFlowEnd, isEnoughCustomerInfo, isCustomerTrusted, isCashPayRequired, isCustomerAddressFilled, handleSubmit, is_single_option, resetBookingFailedValues,
  ticket
}) => {
  const { submitting } = booking_reservation_form_values;
  if (!isBookingFlowEnd) return <></>;
  if (!isEnoughCustomerInfo) return <></>;
  if (!isCustomerTrusted) return <></>;

  const isAnyErrors = () => {
    return booking_reservation_form_values.errors && Object.keys(booking_reservation_form_values.errors).length
  }

  const isPaymentSolutionReady = () => {
    return !!payment_solution.stripe_key || !!payment_solution.square_location_id
  }

  return (
    <div className="reservation-confirmation">
      <div className="note">
        <div dangerouslySetInnerHTML={{ __html: Autolinker.link(booking_page.note) }} />
      </div>

      <a href="#"
        className="btn btn-tarco"
        onClick={(_event) => {
          if (isAnyErrors()) {
            $("#customer-info-modal").modal("show");
          }
          else if (!ticket?.ticket_code && isPaymentSolutionReady() && booking_page.online_payment_enabled && !isCashPayRequired) {
            set_booking_reservation_form_values(prev => ({...prev, is_paying_booking: true}))
          }
          else if (isCashPayRequired && !isCustomerAddressFilled) {
            set_booking_reservation_form_values(prev => ({...prev, is_filling_address: true}))
          }
          else {
            handleSubmit()
          }
        }}
        disabled={submitting}
      >
        {submitting ? (
          <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
        ) : (
          i18n.confirm_reservation
        )}
      </a>
      <BookingFailedArea
        booking_failed={booking_reservation_form_values.booking_failed}
        booking_failed_message={booking_reservation_form_values.errors?.booking_failed_message}
        i18n={i18n}
        is_single_option={is_single_option}
        resetBookingFailedValues={resetBookingFailedValues}
      />
    </div>
  )
}

export default BookingReservationButton
