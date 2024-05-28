
"use strict";

import React from "react";
import { ErrorMessage } from "shared/components";

const BookingFailedArea = ({booking_failed, booking_failed_message, i18n, is_single_option, resetBookingFailedValues}) => {
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
    </div>
  )
}

export default BookingFailedArea;
