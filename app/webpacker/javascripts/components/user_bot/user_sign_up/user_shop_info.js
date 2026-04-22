"use strict";

import React, { useState, useEffect } from "react";

import { UsersServices } from "user_bot/api";
import AddressView from "shared/address_view";
import { RequiredLabel, ErrorMessage } from "shared/components";
import I18n from 'i18n-js/index.js.erb';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const UserShopInfo = ({props, finalView}) => {
  const [is_shop_profile_created, setShopProfile] = useState(false)
  const [is_shop_profile_checked, setCheckShopProfile] = useState(false)
  const [company_name, setCompanyName] = useState()
  const [company_phone_number, setCompanyPhoneNumber] = useState()
  const [company_email, setCompanyEmail] = useState()
  const [companyNameError, setCompanyNameError] = useState(null)
  const [companyEmailError, setCompanyEmailError] = useState(null)
  const { page_title, save_btn, successful_message_html } = props.i18n.shop_info;
  const required_label = I18n.t("common.required_label");

  useEffect(() => {
    const checkShop = async () => {
      const [error, response] = await UsersServices.checkShop({social_service_user_id: props.social_user, staff_token: props.staff_token })

      if (response.data.redirect_url) {
        window.gtag('event', 'sign_up_success', {
          'event_category': 'user',
          'event_label': 'sign_up'
        });
        window.location.href = response.data.redirect_url;
        return;
      }

      setShopProfile(response.data.is_shop_profile_created)
      setCheckShopProfile(true)
    }

    checkShop()
  }, [])

  const validateLocalFields = () => {
    let valid = true;

    if (!company_name || !company_name.trim()) {
      setCompanyNameError(I18n.t("errors.messages.blank"));
      valid = false;
    } else {
      setCompanyNameError(null);
    }

    if (!company_email || !company_email.trim()) {
      setCompanyEmailError(I18n.t("errors.messages.blank"));
      valid = false;
    } else if (!EMAIL_REGEX.test(company_email.trim())) {
      setCompanyEmailError(I18n.t("errors.messages.invalid"));
      valid = false;
    } else {
      setCompanyEmailError(null);
    }

    return valid;
  }

  const onSubmit = async (data) => {
    if (!validateLocalFields()) {
      return;
    }

    const [error, response] = await UsersServices.createShop({...data, company_name, company_phone_number, company_email});

    if (error) {
      const errResponse = error.response;
      if (errResponse && errResponse.status === 422 && errResponse.data && errResponse.data.errors) {
        const errors = errResponse.data.errors;
        if (errors.company_name) setCompanyNameError(errors.company_name.join(", "));
        if (errors.company_email) setCompanyEmailError(errors.company_email.join(", "));
      }
      return;
    }

    if (response.status == 200) {
      if (response.data && response.data.redirect_url) {
        window.gtag('event', 'sign_up_success', {
          'event_category': 'user',
          'event_label': 'sign_up'
        });
        window.location.href = response.data.redirect_url;
      } else {
        setShopProfile(true)
      }
    }
  }

  if (!is_shop_profile_checked) {
    return <></>
  }

  if (is_shop_profile_created) {
    return finalView
  }

  return (
    <>
      <h2 className="centerize">
        {page_title}
      </h2>
      <div className="address-form">
        <div className="reminder-mark centerize">
          {I18n.t("user_bot.guest.user_sign_up.reminder_message")}
        </div>
        <h4>
          <RequiredLabel label={I18n.t("common.shop_name")} required_label={required_label} />
        </h4>
        <div className="field">
          <input
            value={company_name || ''}
            onChange={(e) => setCompanyName(e.target.value)}
            type="text"
            className={companyNameError ? "field-error" : ""}
          />
          {companyNameError && <ErrorMessage error={companyNameError} />}
        </div>
        <h4>
          <label>{I18n.t("common.shop_phone_number")}</label>
        </h4>
        <div className="field">
          <input
            value={company_phone_number || ''}
            onChange={(e) => setCompanyPhoneNumber(e.target.value)}
            type="text"
          />
        </div>
        <h4>
          <RequiredLabel label={I18n.t("common.shop_email")} required_label={required_label} />
        </h4>
        <div className="field">
          <input
            value={company_email || ''}
            onChange={(e) => setCompanyEmail(e.target.value)}
            type="email"
            className={companyEmailError ? "field-error" : ""}
          />
          {companyEmailError && <ErrorMessage error={companyEmailError} />}
        </div>
      </div>
      <div className="reminder-mark centerize">
        {I18n.t("user_bot.guest.user_sign_up.address_required_hint")}
      </div>
      <AddressView
        save_btn_text={save_btn}
        handleSubmitCallback={onSubmit}
      />
    </>
  )
}

export default UserShopInfo;
