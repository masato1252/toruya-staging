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
  is_trial_member,
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

  // 送信方法に応じたメッセージを取得
  const getNotificationMessage = () => {
    let method = '';
    if (customer_notification_channel === 'line') {
      method = 'LINE';
    } else if (customer_notification_channel === 'sms') {
      method = 'ショートメッセージ';
    } else {
      method = 'メール';
    }
    return `ご予約内容を${method}でお送りしています。`;
  };

  // 追加文の表示判定
  const getAdditionalContent = () => {
    // 店舗側LINE未連携の場合 → 何もなし
    if (!line_settings_verified) {
      return null;
    }

    // 店舗側LINE連携済みの場合
    if (skip_social_customer) {
      // ユーザ側「LINEを持っていない」を選択（LINEログインしていない時）
      if (is_free_plan) {
        // 店舗が無料プラン → 追加文①「LINE通知リクエスト案内文」
        return {
          type: 'line_request',
          url: reservation_id ? `/line_notice_requests?reservation_id=${reservation_id}` : null
        };
      } else if (!is_trial_member) {
        // 店舗が有料プラン加入中（試用期間外） → 追加文②「LINE連携のススメ」
        return {
          type: 'line_recommendation',
          url: social_account_login_url
        };
      }
    } else {
      // ユーザ側LINEログイン状態で仮予約した時
      if (is_free_plan) {
        // 店舗が無料プラン → 追加文①「LINE通知リクエスト案内文」
        return {
          type: 'line_request',
          url: reservation_id ? `/line_notice_requests?reservation_id=${reservation_id}` : null
        };
      }
    }

    return null;
  };

  const additionalContent = getAdditionalContent();

  return (
    <div className="done-view">
      <h3 className="title">
        仮予約が完了しました
      </h3>
      
      <div className="message">
        {getNotificationMessage()}
      </div>

      {/* 追加文の表示 */}
      {additionalContent && additionalContent.type === 'line_request' && additionalContent.url && (
        <div className="margin-around">
          <p>LINEで通知を受け取りたい方は<br />リクエストしてください。</p>
          <a href={additionalContent.url} className="btn btn-success" style={{ backgroundColor: '#06C755', borderColor: '#06C755' }}>
            LINEで通知をリクエスト
          </a>
        </div>
      )}

      {additionalContent && additionalContent.type === 'line_recommendation' && additionalContent.url && (
        <div className="margin-around">
          <p>LINE連携すると<br />ご予約内容や前日のリマインドを<br />LINEで受け取ることができます。</p>
          <a href={additionalContent.url} className="btn btn-success" style={{ backgroundColor: '#06C755', borderColor: '#06C755' }}>
            LINE連携
          </a>
        </div>
      )}

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
