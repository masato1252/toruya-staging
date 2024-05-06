"use strict";

import React from "react";

// deprecated in c207a12d164901196c71d2e15fbe56c7cb206a30
const BookingCodeView = ({booking_reservation_form_values, i18n, neverTryToFindCustomer, isCustomerTrusted}) => {
  const {
    is_confirming_code,
    is_asking_confirmation_code,
    booking_code_failed_message,
  } = booking_reservation_form_values;

  if (neverTryToFindCustomer) return <></>;
  if (isCustomerTrusted) return <></>;

  return (
    <div className="customer-type-options">
      <h4>
        {i18n.booking_code.code}
      </h4>
      <div className="centerize">
        <div className="desc">
          {i18n.message.booking_code_message}
        </div>
        <Field
          className="booking-code"
          name="booking_reservation_form[booking_code][code]"
          component="input"
          placeholder="012345"
          type="tel"
        />
        <button
          onClick={this.confirmCode}
          className="btn btn-tarco" disabled={is_confirming_code || is_asking_confirmation_code}>
          {is_confirming_code ? (
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
          ) : (
            i18n.confirm
          )}
        </button>
        <ErrorMessage error={booking_code_failed_message} />
        <div className="resend-row">
          <a href="#"
            onClick={this.askConfirmCode}
            disabled={is_confirming_code || is_asking_confirmation_code}
          >
            {is_asking_confirmation_code ? (
              <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
            ) : (
              i18n.booking_code.resend
            )}
          </a>
        </div>
      </div>
    </div>
  );
}

export default BookingCodeView
