"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

import { LineLoginBtn } from "shared/booking";

const SocialCustomerLogin = ({ booking_reservation_form_values, social_account_login_url, set_booking_reservation_form_values, social_account_skippable }) => {
  const { booking_option_ids, booking_date, booking_at, selected_staff_id } = booking_reservation_form_values

  return (
    <>
      <div className="social-login-block centerize">
        <LineLoginBtn
          social_account_login_url={`${social_account_login_url}&booking_option_ids=${booking_option_ids.join(",")}&booking_date=${booking_date}&booking_at=${booking_at}&staff_id=${selected_staff_id}`}>
          <h3 className="desc" dangerouslySetInnerHTML={{ __html: I18n.t("booking_page.message.line_reminder_messages_html") }} />
        </LineLoginBtn>
      </div>
      {social_account_skippable && (
        <div className="action-block centerize">
          <button
            className="btn btn-gray"
            onClick={() => {
              set_booking_reservation_form_values(prev => ({...prev, skip_social_customer: true}))
            }}>
            {I18n.t("booking_page.i_dont_use_line")}
          </button>
        </div>
      )}
    </>
  )
}

export default SocialCustomerLogin
