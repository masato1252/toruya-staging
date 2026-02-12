"use strict";

import React from "react";
import Autolinker from 'autolinker';

import BookingFailedArea from "./booking_failed_area";
import { isValidEmail } from "./current_customer_info";

const BookingReservationButton = ({
  set_booking_reservation_form_values, booking_reservation_form_values, i18n, booking_page, payment_solution,
  isBookingFlowEnd, isEnoughCustomerInfo, isCustomerTrusted, isOnlinePayment, isCustomerAddressRequired, isCustomerAddressFilled, handleSubmit, is_single_option, resetBookingFailedValues,
  tickets, requiresEmailInput
}) => {
  if (!isBookingFlowEnd) return <></>;
  if (!isEnoughCustomerInfo) return <></>;
  if (!isCustomerTrusted) return <></>;

  const submitting = booking_reservation_form_values.submitting;

  // メール入力が必要なのにメールが未入力or形式不正の場合は非活性
  const isEmailInvalid = requiresEmailInput && !isValidEmail(booking_reservation_form_values.customer_email);

  const isAnyErrors = () => {
    return booking_reservation_form_values.errors && Object.keys(booking_reservation_form_values.errors).length
  }

  const isPaymentSolutionReady = () => {
    return !!payment_solution.stripe_key || !!payment_solution.square_location_id
  }

  const isButtonDisabled = submitting || isEmailInvalid;

  return (
    <div className="reservation-confirmation">
      {booking_page.note && booking_page.note.trim().length > 0 && !submitting && (
        <div className="note">
          <div dangerouslySetInnerHTML={{ __html: Autolinker.link(booking_page.note) }} />
        </div>
      )}

      <a href="#"
        className={`btn btn-tarco ${isButtonDisabled ? 'disabled' : ''}`}
        onClick={(_event) => {
          if (isButtonDisabled) return;
          if (isAnyErrors()) {
            $("#customer-info-modal").modal("show");
          }
          else if (tickets.length !== booking_reservation_form_values.booking_option_ids.length && isPaymentSolutionReady() && isOnlinePayment) {
            set_booking_reservation_form_values(prev => ({...prev, is_paying_booking: true}))
          }
          else if (!isOnlinePayment && isCustomerAddressRequired && !isCustomerAddressFilled) {
            set_booking_reservation_form_values(prev => ({...prev, is_filling_address: true}))
          }
          else {
            set_booking_reservation_form_values(prev => ({...prev, submitting: true}))
            handleSubmit()
          }
        }}
        disabled={isButtonDisabled}
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
        booking_page_url={booking_page.url}
        i18n={i18n}
        is_single_option={is_single_option}
        resetBookingFailedValues={resetBookingFailedValues}
      />
    </div>
  )
}

export default BookingReservationButton