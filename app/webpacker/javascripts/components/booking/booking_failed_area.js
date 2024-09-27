
"use strict";

import React from "react";
import { ErrorMessage } from "shared/components";

const BookingFailedArea = ({booking_failed, booking_failed_message, i18n, is_single_option, resetBookingFailedValues, booking_page_url}) => {
  if (!booking_failed) return <></>;

  return (
    <div className="booking-failed-message">
      <ErrorMessage error={booking_failed_message} />
      {
        (!is_single_option) &&
          <button onClick={resetBookingFailedValues} className="btn btn-orange reset">
            {i18n.reset_button}
          </button>
      }

      <div className="margin-around centerize">
        <a href={booking_page_url} className="btn btn-tarco">{i18n.back_to_book}</a>
      </div>
    </div>
  )
}

export default BookingFailedArea;
