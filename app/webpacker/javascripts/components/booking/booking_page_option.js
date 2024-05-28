"use strict";

import React from "react";
import { TicketPriceDesc } from "shared/components";

const BookingPageOption = ({ booking_option_value, selectBookingOptionCallback, i18n, booking_start_at, last_selected_option_id, ticket }) => {
  let option_content;
  const {
    open_details,
    close_details,
    booking_option_required_time,
    minute,
    last_selected_option,
  } = i18n;

  const handleOptionClick = (booking_option_id) => {
    if (selectBookingOptionCallback) {
      selectBookingOptionCallback(booking_option_id)
    }
  }

  if (selectBookingOptionCallback || !booking_start_at || !booking_start_at.isValid()) {
    option_content = `${booking_option_required_time}${booking_option_value.minutes}${minute}`;
  }
  else {
    booking_start_at = booking_start_at.add(booking_option_value.minutes, "minutes")
    option_content = `${booking_start_at.format("HH:mm")} ${i18n.booking_end_at}`
  }

  const renderPrice = () => {
    if (ticket && ticket.ticket_code) {
      return (
        <>
          <i className="fa fa-ticket-alt text-gray-500"></i> {I18n.t("common.left_ticket")}{ticket.total_quota - ticket.consumed_quota}/{ticket.total_quota} {I18n.t("common.times")}
        </>
      )
    }
    else if (ticket && !ticket.ticket_code)
      return (
        <>
          {booking_option_value.price} <i className="fa fa-ticket-alt text-gray-500"></i> <TicketPriceDesc amount={booking_option_value.price_amount} ticket_quota={ticket.total_quota} />
        </>
      )
    else {
      return booking_option_value.price
    }
  }

  return (
    <div className="result-field">
      <div className="booking-option-field" data-controller="collapse" data-collapse-status="closed">
        <div className="booking-option-info" onClick={() => handleOptionClick(booking_option_value.id)}>
          {last_selected_option_id && last_selected_option_id === booking_option_value.id && (
            <div className="last-selected-option">
              <i className="fa fa-repeat" aria-hidden="true"></i>{last_selected_option}
            </div>
          )}
          <div className="booking-option-name">
            <b>
              {booking_option_value.label}
            </b>
          </div>

          {option_content}
        </div>

        <div className="booking-option-row">
          <span>
            {renderPrice()}
          </span>

          {booking_option_value.memo && booking_option_value.memo.length &&
            <span className="booking-option-details-toggler" data-action="click->collapse#toggle">
              <a className="toggler-link" data-target="collapse.openToggler">{close_details}<i className="fa fa-chevron-up" aria-hidden="true"></i></a>
              <a className="toggler-link" data-target="collapse.closeToggler">{open_details}<i className="fa fa-chevron-down" aria-hidden="true"></i></a>
            </span>
          }
        </div>
        <div className="booking-option-row" data-target="collapse.content">
          {booking_option_value.memo}
        </div>
      </div>
    </div>
  )
}

export default BookingPageOption
