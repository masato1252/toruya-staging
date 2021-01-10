import React from "react";

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

export const BookingEndInfo = ({start_at}) => (
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

export const AddLineFriendInfo = ({social_account_add_friend_url}) => (
  social_account_add_friend_url ? (
    <div className="message centerize">
      <h3 className="desc" dangerouslySetInnerHTML={{ __html: I18n.t("booking_page.done.add_friend_messages_html") }} />
      <a href={social_account_add_friend_url} className="btn line-button">
        <span className="fab fa-line" aria-hidden="true"></span>
        {I18n.t("booking_page.done.add_friend_btn")}
      </a>
    </div>
  ) : <></>
)

