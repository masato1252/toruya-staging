"use strict"

import React, { useState } from "react";
import Rails from "rails-ujs";
import { TopNavigationBar } from "shared/components";
import { COUNTRY_CODES, toInternationalNumber } from "shared/customer_verification";
import I18n from 'i18n-js/index.js.erb';

const INPUT_MODE_PHONE = "phone";
const INPUT_MODE_EMAIL = "email";

const StaffNew = ({ props }) => {
  const [inputMode, setInputMode] = useState(INPUT_MODE_PHONE);
  const [countryCode, setCountryCode] = useState(props.default_country_code || '+81');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [email, setEmail] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (isSubmitting) return;

    let phoneNumberOrEmail;
    if (inputMode === INPUT_MODE_PHONE) {
      if (!phoneNumber) return;
      phoneNumberOrEmail = toInternationalNumber(countryCode, phoneNumber);
    } else {
      if (!email) return;
      phoneNumberOrEmail = email;
    }

    setIsSubmitting(true);

    const form = document.createElement('form');
    form.method = 'POST';
    form.action = props.submit_url;

    const csrfInput = document.createElement('input');
    csrfInput.type = 'hidden';
    csrfInput.name = 'authenticity_token';
    csrfInput.value = Rails.csrfToken();
    form.appendChild(csrfInput);

    const valueInput = document.createElement('input');
    valueInput.type = 'hidden';
    valueInput.name = 'phone_number_or_email';
    valueInput.value = phoneNumberOrEmail;
    form.appendChild(valueInput);

    document.body.appendChild(form);
    form.submit();
  };

  const isValid = inputMode === INPUT_MODE_PHONE ? phoneNumber.length > 0 : email.length > 0;

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={props.back_url}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={I18n.t("user_bot.dashboards.settings.staffs.new_page_title")}
            />

            <div className="margin-around centerize">
              <div className="my-2">{I18n.t("user_bot.dashboards.settings.staffs.new_page_desc")}</div>

              <div style={{ display: 'flex', justifyContent: 'center', gap: '8px', marginBottom: '16px' }}>
                <button
                  type="button"
                  className={`btn ${inputMode === INPUT_MODE_PHONE ? 'btn-tarco' : 'btn-gray'}`}
                  onClick={() => setInputMode(INPUT_MODE_PHONE)}
                  style={{ flex: 1, maxWidth: '140px' }}
                >
                  <i className="fas fa-phone" style={{ marginRight: '4px' }}></i>
                  {I18n.t("common.cellphone_number")}
                </button>
                <button
                  type="button"
                  className={`btn ${inputMode === INPUT_MODE_EMAIL ? 'btn-tarco' : 'btn-gray'}`}
                  onClick={() => setInputMode(INPUT_MODE_EMAIL)}
                  style={{ flex: 1, maxWidth: '140px' }}
                >
                  <i className="fas fa-envelope" style={{ marginRight: '4px' }}></i>
                  {I18n.t("common.email")}
                </button>
              </div>

              {inputMode === INPUT_MODE_PHONE ? (
                <div style={{ display: 'flex', gap: '8px', marginBottom: '12px' }}>
                  <select
                    className="form-control"
                    style={{ width: '180px', flexShrink: 0 }}
                    value={countryCode}
                    onChange={(e) => setCountryCode(e.target.value)}
                  >
                    {COUNTRY_CODES.map(country => (
                      <option key={country.code} value={country.code}>
                        {country.label}
                      </option>
                    ))}
                  </select>
                  <input
                    type="tel"
                    className="form-control"
                    style={{ flex: 1 }}
                    value={phoneNumber}
                    onChange={(e) => setPhoneNumber(e.target.value)}
                    placeholder="09012345678"
                  />
                </div>
              ) : (
                <div style={{ marginBottom: '12px' }}>
                  <input
                    type="email"
                    className="form-control"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="example@example.com"
                  />
                </div>
              )}

              <button
                type="button"
                className="btn btn-tarco"
                disabled={!isValid || isSubmitting}
                onClick={handleSubmit}
              >
                {isSubmitting
                  ? <i className="fa fa-spinner fa-spin fa-fw" aria-hidden="true"></i>
                  : I18n.t("common.send")}
              </button>
            </div>

            <div className="flex justify-center">
              <div
                className="margin-around break-line-content"
                dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.settings.staffs.new_page_methods_html") }}
              />
            </div>
          </div>
        </div>
        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  );
};

export default StaffNew;
