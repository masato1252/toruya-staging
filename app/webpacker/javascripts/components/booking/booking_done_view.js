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
  customer_notification_channel,
  is_free_plan,
  line_settings_verified,
  reservation_id
}) => {
  const {
    title,
    message1,
    message_line,
    message_sms,
    message_email,
    back_to_book
  } = i18n.done

  // 無料プランの場合の通知チャンネルメッセージを修正
  const getNotificationMessage = () => {
    if (is_free_plan) {
      // 無料プランの場合は常にメール通知
      return message_email || I18n.t("booking_page.done.message_email");
    } else {
      // 有料プランの場合は通知チャンネルに応じたメッセージ
      if (customer_notification_channel === 'line') {
        return message_line;
      } else if (customer_notification_channel === 'sms') {
        return message_sms;
      } else {
        return message_email;
      }
    }
  };

  // LINEリクエストボタンのURL
  const lineNoticeRequestUrl = reservation_id ? `/line_notice_requests/new?reservation_id=${reservation_id}` : null;
  
  // LINEリクエストボタンを表示するか判定
  const shouldShowLineRequestButton = is_free_plan && line_settings_verified && lineNoticeRequestUrl;

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
              {getNotificationMessage()}
            </div>
            {!is_free_plan && customer_notification_channel === 'line' ? <CheckInLineBtn social_account_add_friend_url={social_account_add_friend_url} /> : null}
            
            {/* 無料プラン かつ LINE連携済み の場合、LINE通知リクエストボタンを表示 */}
            {shouldShowLineRequestButton && (
              <div className="margin-around">
                <a href={lineNoticeRequestUrl} className="btn btn-success" style={{ backgroundColor: '#06C755', borderColor: '#06C755' }}>
                  {I18n.t("booking_page.done.request_line_notice")}
                </a>
              </div>
            )}
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
