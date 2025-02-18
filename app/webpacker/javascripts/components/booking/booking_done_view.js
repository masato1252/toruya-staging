"use strict";

import React from "react";
import moment from 'moment-timezone';

import I18n from 'i18n-js/index.js.erb';
import { CheckInLineBtn, LineLoginBtn } from "shared/booking";
import { ticketExpireDate } from 'libraries/helper'

const BookingDoneView = ({
  i18n,
  social_account_add_friend_url,
  social_account_login_url,
  tickets,
  booking_date,
  booking_page_url,
  booking_option_ids,
  skip_social_customer,
  function_access_id,
  customer_notification_channel
}) => {
  const {
    title,
    message1,
    message_line,
    message_sms,
    message_email,
    back_to_book
  } = i18n.done

  return (
    <div className="done-view">
      <h3 className="title">
        {title}
      </h3>
      {
        skip_social_customer && customer_notification_channel === 'line' ? (
          <>
            <div className="message" dangerouslySetInnerHTML={{ __html: I18n.t("booking_page.done.no_line_message1_html") }} />
            <div className="message" dangerouslySetInnerHTML={{ __html: I18n.t("booking_page.done.no_line_message2_html") }} />
            <LineLoginBtn social_account_login_url={social_account_login_url} />
          </>
        ) : (
          <>
            <div className="message">
              {message1}
              <br />
              {customer_notification_channel === 'line' ? message_line : customer_notification_channel === 'sms' ? message_sms : message_email}
            </div>
            {customer_notification_channel === 'line' ? <CheckInLineBtn social_account_add_friend_url={social_account_add_friend_url} /> : null}
          </>
        )
      }

      {tickets?.length > 0 && tickets.map(ticket => (
        <React.Fragment key={ticket.id}>
          <div dangerouslySetInnerHTML={{ __html: ticket.booking_option_name }} />
          {ticket.consumed_quota + 1 == ticket.total_quota && (
            <div className="message" dangerouslySetInnerHTML={{ __html: I18n.t("booking_page.done.no_ticket_left_message_html") }} />
          )}

          {ticket.consumed_quota + 1 !== ticket.total_quota && (
            <div className="message" dangerouslySetInnerHTML={{
              __html: I18n.t("booking_page.done.ticket_left_message_html", {
                remaining_ticket_quota: ticket.total_quota - ticket.consumed_quota - 1,
                expire_date: ticket.expire_date || ticketExpireDate(moment(booking_date), ticket.expire_month)}
              )
            }} />
          )}
        </React.Fragment>
      ))}

      <div className="margin-around">
        <a href={`${booking_page_url}?last_booking_option_ids=${booking_option_ids}${function_access_id ? `&function_access_id=${function_access_id}` : ''}`} className="btn btn-tarco">{back_to_book}</a>
      </div>
    </div>
  )
}

export default BookingDoneView;
