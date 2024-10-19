"use strict";

import React, { useState } from "react";
import Rails from "rails-ujs";
import axios from "axios";

import { ErrorMessage } from "shared/components";

export const CustomerIdentificationView = ({social_user_id, customer_id, identifiedCallback, i18n, support_phonetic_name}) => {
  const { name, last_name, first_name, phone_number, next_step, booking_code, message, confirm,
    title_html, phonetic_name, phonetic_last_name, phonetic_first_name, email, create_customer_info } = i18n;

  const phone_number_identification_feature_enabled = false;
  const [customer_last_name, setCustomerLastName] = useState("")
  const [customer_first_name, setCustomerFirstName] = useState("")
  const [customer_phonetic_last_name, setCustomerPhoneticLastName] = useState("")
  const [customer_phonetic_first_name, setCustomerPhoneticFirstName] = useState("")
  const [customer_phone_number, setCustomerPhoneNumber] = useState("")
  const [identification_code, setIdentificationCode] = useState({})
  const [is_identifying_code, setIdentifyingCode] = useState(false)
  const [is_asking_identification_code, setAskingIdentificationCode] = useState(false)
  const [identification_code_error, setIdentificationCodeError] = useState(null)
  const [is_phone_identified, setPhoneIdentified] = useState(!!customer_id)

  let identifyCodeCall;
  let askIdentificationCodeCall;

  const _is_customer_found = () => {
    return identification_code && !!identification_code.customer_id;
  }

  const _is_all_fields_filled = () => {
    if (support_phonetic_name) {
      return customer_first_name && customer_last_name && customer_phone_number
        && customer_phonetic_last_name && customer_phonetic_first_name;
    }
    else {
      return customer_first_name && customer_last_name && customer_phone_number;
    }
  }

  const signIn = async (event) => {
    event.preventDefault();
    if (!(_is_all_fields_filled())) return;

    const response = await axios({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_customer_sign_in_path(),
      data: {
        social_service_user_id: social_user_id,
        customer_first_name: customer_first_name,
        customer_last_name: customer_last_name,
        customer_phone_number: customer_phone_number,
        customer_phonetic_last_name: customer_phonetic_last_name,
        customer_phonetic_first_name: customer_phonetic_first_name
      },
      responseType: "json"
    })

    const {
      identification_successful,
      errors
    } = response.data;

    setPhoneIdentified(identification_successful)
    setIdentificationCode({...identification_code, customer_id: response.data.customer_id})
    identifiedCallback(response.data)
  }

  const identifyCode = async (event) => {
    event.preventDefault();

    if (!(_is_all_fields_filled())) return;
    if (identifyCodeCall) return;

    setIdentifyingCode(true)
    identifyCodeCall = "loading";

    const response = await axios({
      method: "GET",
      url: Routes.lines_identify_code_path(),
      params: {
        social_service_user_id: social_user_id,
        uuid: identification_code.uuid,
        customer_first_name: customer_first_name,
        customer_last_name: customer_last_name,
        customer_phone_number: customer_phone_number,
        customer_phonetic_last_name: customer_phonetic_last_name,
        customer_phonetic_first_name: customer_phonetic_first_name,
        code: identification_code.code
      },
      responseType: "json"
    })

    const {
      identification_successful,
      errors
    } = response.data;

    setPhoneIdentified(identification_successful)
    setIdentificationCode({...identification_code, customer_id: response.data.customer_id})
    setIdentifyingCode(false)
    identifyCodeCall = null;

    if (errors) {
      setIdentificationCodeError(errors.message);
    }
    else {
      identifiedCallback(response.data)
    }
  }

  const askIdentificationCode = async (event) => {
    event.preventDefault();

    if (askIdentificationCodeCall) return;
    if (!customer_phone_number) return;

    setAskingIdentificationCode(true)
    setIdentificationCodeError(null)
    setIdentificationCode({...identification_code, code: ""})
    askIdentificationCodeCall = "loading";

    const response = await axios({
      method: "GET",
      url: Routes.lines_ask_identification_code_path(),
      params: {
        social_service_user_id: social_user_id,
        customer_phone_number: customer_phone_number,
      },
      responseType: "json"
    })

    const {
      errors
    } = response.data;

    setIdentificationCode(response.data.identification_code)
    setAskingIdentificationCode(false)
    askIdentificationCodeCall = null;
    document.getElementById("booking-code").focus();

    if (errors) setIdentificationCodeError(errors.message)
  }

  const renderIdentificationCode = () => {
    return (
      <div className="customer-type-options">
        <h4>
          {booking_code.code}
        </h4>
        <div className="centerize">
          <div className="desc">
            {message.booking_code_message}
          </div>
          <input
            id="booking-code"
            className="booking-code"
            placeholder="012345"
            type="tel"
            value={identification_code.code}
            onChange={(e) => setIdentificationCode({...identification_code, code: e.target.value})}
          />
          <button
            onClick={identifyCode}
            className="btn btn-tarco" disabled={is_identifying_code || is_asking_identification_code || !identification_code.code}>
            {is_identifying_code ? (
              <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
            ) : (
              confirm
            )}
          </button>
          <ErrorMessage error={identification_code_error} />
          <div className="resend-row">
            <a href="#"
              onClick={askIdentificationCode}
              disabled={is_identifying_code || is_asking_identification_code || !identification_code.code}
            >
              {is_asking_identification_code ? (
                <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
              ) : (
                booking_code.resend
              )}
            </a>
          </div>
        </div>
      </div>
    )
  }

  if (customer_id || (is_phone_identified && identification_code.customer_id)) {
    return (
      <div className="whole-page-center final"></div>
    )
  }

  return (
    <>
      <div className="header">
        <div className="header-title-part centerize">
          <h3 dangerouslySetInnerHTML={{ __html: title_html }} />
        </div>
      </div>
      <div className="customer-type-options">
        <h4>
          {name}
        </h4>
        <div>
          <input
            placeholder={last_name}
            type="text"
            value={customer_last_name}
            onChange={(e) => setCustomerLastName(e.target.value)}
          />
          <input
            placeholder={first_name}
            type="text"
            value={customer_first_name}
            onChange={(e) => setCustomerFirstName(e.target.value)}
          />
        </div>
        {support_phonetic_name ? (
          <>
            <br />
            <div>
              <input
            placeholder={phonetic_last_name}
            type="text"
            value={customer_phonetic_last_name}
            onChange={(e) => setCustomerPhoneticLastName(e.target.value)}
          />
          <input
            placeholder={phonetic_first_name}
            type="text"
              value={customer_phonetic_first_name}
              onChange={(e) => setCustomerPhoneticFirstName(e.target.value)}
            />
          </div>
          </>
        ) : null}
        <h4>
          {phone_number}
        </h4>
        <input
          placeholder="0123456789"
          type="tel"
          value={customer_phone_number}
          onChange={(e) => setCustomerPhoneNumber(e.target.value)}
        />

        {!_is_customer_found() && !identification_code.uuid ? (
          <div className="centerize">
            <a href="#" className="btn btn-tarco find-customer" onClick={phone_number_identification_feature_enabled ? askIdentificationCode : signIn} disabled={is_asking_identification_code || !_is_all_fields_filled()}>
              {is_asking_identification_code ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : next_step}
            </a>
          </div>
        ) : null}
      </div>
      {identification_code.uuid && !is_phone_identified ? renderIdentificationCode() : null}
    </>
  )

}

export default CustomerIdentificationView;
