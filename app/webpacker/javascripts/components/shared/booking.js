import React from "react";
import I18n from 'i18n-js/index.js.erb';
import LineIconBaseImg from 'assets/booking/btn_login_base.png';

export const BookingStartInfo = ({start_at}) => (
  <div className="start-yet-view">
    <h3 className="title">
      {I18n.t("booking_page.start_yet.title")}
    </h3>
    <div className="message">
      {I18n.t("booking_page.start_yet.message1")}
      <br />
      <strong>{start_at}～</strong>
      <br />
      {I18n.t("booking_page.start_yet.message2")}
    </div>
  </div>
)

export const BookingEndInfo = () => (
  <div className="booking-info">
    <div className="ended-view">
      <h3 className="title">
        {I18n.t("booking_page.ended.title")}
      </h3>
      <div className="message">
        {I18n.t("booking_page.ended.message1")}
        <br />
        {I18n.t("booking_page.ended.message2")}
      </div>
    </div>
  </div>
)

export const ServiceStartInfo = ({start_at}) => (
  <div className="start-yet-view">
    <h3 className="title">
      {I18n.t("booking_page.start_yet.title")}
    </h3>
    <div className="message">
      {I18n.t("booking_page.start_yet.message1_online_service")}
      <br />
      <strong>{start_at}～</strong>
      <br />
      {I18n.t("booking_page.start_yet.message2")}
    </div>
  </div>
)

export const ServiceEndInfo = () => (
  <div className="booking-info">
    <div className="ended-view">
      <h3 className="title">
        {I18n.t("booking_page.ended.title")}
      </h3>
      <div className="message">
        {I18n.t("booking_page.ended.message1_online_service")}
        <br />
        {I18n.t("booking_page.ended.message2")}
      </div>
    </div>
  </div>
)


export const CheckInLineBtn = ({social_account_add_friend_url, btn_text, children}) => (
  social_account_add_friend_url ? (
    <div className="message centerize">
      {children}
      <a href={social_account_add_friend_url} className="btn line-button with-wording with-logo">
        <img src={LineIconBaseImg} />
        {btn_text || I18n.t("booking_page.done.check_in_line_btn")}
      </a>
    </div>
  ) : <></>
)

export const AddLineFriendInfo = ({social_account_add_friend_url, children}) => (
  social_account_add_friend_url ? (
    <div className="message centerize">
      {children || <h3 className="desc" dangerouslySetInnerHTML={{ __html: I18n.t("booking_page.done.add_friend_messages_html") }} />}
      <a href={social_account_add_friend_url} className="btn line-button with-wording with-logo">
        <img src={LineIconBaseImg} />
        {I18n.t("booking_page.done.add_friend_btn")}
      </a>
    </div>
  ) : <></>
)

export const LineLoginBtn = ({social_account_login_url, btn_text, children}) => (
  social_account_login_url ? (
    <div className="message centerize">
      {children}
      <a href={social_account_login_url} className="btn line-button with-wording with-logo" data-method="post">
        <img src={LineIconBaseImg} />
        {btn_text || I18n.t("common.line_login_btn_word")}
      </a>
    </div>
  ) : <></>
)

