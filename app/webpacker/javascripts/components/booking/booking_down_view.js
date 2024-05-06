"use strict";

import React from "react";

import { CheckInLineBtn } from "shared/booking";

const BookingDownView = ({i18n, social_account_add_friend_url}) => {
  const {
    title,
    message1,
    message2
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
    </div>
  )
}

export default BookingDownView;
