"use strict";

import React from "react";
import moment from 'moment-timezone';

import { CheckInLineBtn } from "shared/booking";
import { ticketExpireDate } from 'libraries/helper'

const BookingDoneView = ({i18n, social_account_add_friend_url, ticket, booking_date, booking_page_url, booking_option_id}) => {
  const {
    title,
    message1,
    message2,
    back_to_book
  } = i18n.done

  return (
    <div className="done-view">
      <h3 className="title">
        {title}
      </h3>
      <div className="message">
        {message1}
        <br />
        {message2}
      </div>

      <CheckInLineBtn social_account_add_friend_url={social_account_add_friend_url} />

      {ticket && ticket.consumed_quota + 1 == ticket.total_quota && (
        <div className="message" dangerouslySetInnerHTML={{ __html: I18n.t("booking_page.done.no_ticket_left_message_html") }} />
      )}

      {ticket && ticket.consumed_quota + 1 !== ticket.total_quota && (
        <div className="message" dangerouslySetInnerHTML={{
          __html: I18n.t("booking_page.done.ticket_left_message_html", {
            remaining_ticket_quota: ticket.total_quota -ticket.consumed_quota - 1,
            expire_date: ticket.expire_date || ticketExpireDate(moment(booking_date), ticket.expire_month)}
          )
        }} />
      )}

      <div className="margin-around">
        <a href={`${booking_page_url}?last_booking_option_id=${booking_option_id}`} className="btn btn-tarco">{back_to_book}</a>
      </div>
    </div>
  )
}

export default BookingDoneView;
