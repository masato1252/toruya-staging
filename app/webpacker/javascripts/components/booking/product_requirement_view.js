"use strict";

import React from "react";
import { LineLoginBtn, CheckInLineBtn } from "shared/booking";
import I18n from 'i18n-js/index.js.erb';

const ProductRequirementView  = ({ product_name, social_account_login_url, social_account_add_friend_url, social_customer_exists }) => {
  return (
    <div className="centerize">
      <div className="reminder-mark desc my-4">
        {I18n.t("common.only_for_login_user")}
      </div>
      <div>{I18n.t("booking_page.requirement.message", { product_name: product_name })}</div>
      <div>{I18n.t("booking_page.requirement.contact_shop_owner")}</div>
      <div className="margin-around">
        <CheckInLineBtn
          social_account_add_friend_url={social_account_add_friend_url}
          btn_text={I18n.t("booking_page.requirement.ask_in_line")}
        />
      </div>

      <br />
      {!social_customer_exists && (
        <>
          <p>{I18n.t("booking_page.requirement.login_message")}</p>

          <div className="margin-around">
            <LineLoginBtn
              social_account_login_url={social_account_login_url}
              btn_text={I18n.t("common.line_user_login_btn_word")}
            />
          </div>
        </>
      )}
    </div>
  )
}

export default ProductRequirementView
