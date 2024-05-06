"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

import { LineLoginBtn } from "shared/booking";

const SocialCustomerLogin = ({booking_reservation_form_values, social_account_login_url}) => {
  const { booking_option_id, booking_date, booking_at } = booking_reservation_form_values

  return (
    <div className="social-login-block centerize">
      <LineLoginBtn
        social_account_login_url={`${social_account_login_url}&booking_option_id=${booking_option_id}&booking_date=${booking_date}&booking_at=${booking_at}`}>
        <h3 className="desc" dangerouslySetInnerHTML={{ __html: I18n.t("booking_page.message.line_reminder_messages_html") }} />
      </LineLoginBtn>
    </div>
  )
}

export default SocialCustomerLogin
