"use strict";

import React, { useState } from "react";
import Rails from "rails-ujs";
import axios from "axios";

import { ErrorMessage } from "shared/components";

export const CustomerIdentification = (props) => {
  const { social_user_id, customer_id } = props.social_customer;
  const { name, last_name, first_name, phone_number, confirm_customer_info, booking_code, message, confirm,
    successful_message_html, title_html, phonetic_name, phonetic_last_name, phonetic_first_name, email } = props.i18n;

  const [customer_last_name, setCustomerLastName] = useState("")
  const [customer_first_name, setCustomerFirstName] = useState("")
  const [customer_phonetic_last_name, setCustomerPhoneticLastName] = useState("")
  const [customer_phonetic_first_name, setCustomerPhoneticFirstName] = useState("")
  const [customer_phone_number, setCustomerPhoneNumber] = useState("")
  const [customer_email, setCustomerEmail] = useState("")
  const [is_finding_customer, setFindingCustomer] = useState(false)
  const [is_creating_customer, setCreatingCustomer] = useState(false)
  const [identification_code, setIdentificationCode] = useState({})
  const [is_identifying_code, setIdentifyingCode] = useState(false)
  const [is_asking_identification_code, setAskingIdentificationCode] = useState(false)
  const [identification_code_error, setIdentificationCodeError] = useState(null)
  const [is_customer_identified, setCustomerIdentified] = useState(!!customer_id)

  let identifyCodeCall;
  let askIdentificationCodeCall;
  let findCustomerCall;
  let createCustomerCall;

  const _is_customer_found = () => {
    return identification_code && !!identification_code.customer_id;
  }

  const _is_fields_filled = () => {
    return customer_first_name && customer_last_name && customer_phone_number;
  }

  const _is_all_fields_filled = () => {
    return customer_first_name && customer_last_name && customer_phone_number
      && customer_phonetic_last_name && customer_phonetic_first_name && customer_email;
  }

  const findCustomer = async (event) => {
    event.preventDefault();

    if (!(_is_fields_filled())) return;
    if (findCustomerCall) return;

    setFindingCustomer(true);
    setIdentificationCode({});

    const response = await axios({
      method: "GET",
      url: props.path.find_customer,
      params: {
        social_user_id: social_user_id,
        customer_first_name: customer_first_name,
        customer_last_name: customer_last_name,
        customer_phone_number: customer_phone_number
      },
      responseType: "json"
    })

    const {
      errors
    } = response.data;

    setIdentificationCode(response.data.identification_code)
    setFindingCustomer(false)
    findCustomerCall = null;
  }

  const createCustomer = async (event) => {
    event.preventDefault();

    if (!(_is_all_fields_filled())) return;
    if (createCustomerCall) return;

    setCreatingCustomer(true);

    const response = await axios({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: props.path.create_customer,
      data: {
        social_user_id: social_user_id,
        customer_first_name: customer_first_name,
        customer_last_name: customer_last_name,
        customer_phone_number: customer_phone_number,
        customer_phonetic_last_name: customer_phonetic_last_name,
        customer_phonetic_first_name: customer_phonetic_first_name,
        customer_email: customer_email,
        uuid: identification_code.uuid,
        code: identification_code.code
      },
      responseType: "json"
    })

    const {
      errors
    } = response.data;

    setIdentificationCode({...identification_code, customer_id: response.data.customer_id})
    setCreatingCustomer(false)
    createCustomerCall = null;
  }

  const identifyCode = async (event) => {
    event.preventDefault();

    if (identifyCodeCall) return;

    setIdentifyingCode(true)
    identifyCodeCall = "loading";

    const response = await axios({
      method: "GET",
      url: props.path.identify_code,
      params: {
        social_user_id,
        uuid: identification_code.uuid,
        code: identification_code.code
      },
      responseType: "json"
    })

    const {
      identification_successful,
      errors
    } = response.data;

    setCustomerIdentified(identification_successful)
    setIdentifyingCode(false)
    identifyCodeCall = null;

    if (errors) setIdentificationCodeError(errors.message);
  }

  const askIdentificationCode = async (event) => {
    event.preventDefault();

    if (askIdentificationCodeCall) return;

    setAskingIdentificationCode(true)
    setIdentificationCodeError(null)
    setIdentificationCode({...identification_code, code: ""})
    askIdentificationCodeCall = "loading";

    const response = await axios({
      method: "GET",
      url: props.path.ask_identification_code,
      params: {
        social_user_id,
        customer_id: identification_code.customer_id,
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

    if (errors) setAskingIdentificationCode(errors.message)
  }

  const renderBookingCode = () => {
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

  const renderNewCustomerFields = () => {
    return (
      <>
        <h4>
          {phonetic_name}
        </h4>
        <div className="field">
          <input
            placeholder={phonetic_last_name}
            type="text"
            value={customer_phonetic_last_name}
            onChange={(e) => setCustomerPhoneticLastName(e.target.value)}
          />
        </div>
        <div className="field">
          <input
            placeholder={phonetic_first_name}
            type="text"
            value={customer_phonetic_first_name}
            onChange={(e) => setCustomerPhoneticFirstName(e.target.value)}
          />
        </div>
        <h4>
          {email}
        </h4>
        <div className="field">
          <input
            placeholder="mail@domail.com"
            type="email"
            value={customer_email}
            onChange={(e) => setCustomerEmail(e.target.value)}
          />
        </div>
      </>
    )
  }

  if (is_customer_identified && identification_code.customer_id) {
    return (
      <div className="whole-page-center final">
        <div dangerouslySetInnerHTML={{ __html: successful_message_html }} />
      </div>
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
            <a href="#" className="btn btn-tarco find-customer" onClick={findCustomer} disabled={is_finding_customer || !_is_fields_filled()}>
              {is_finding_customer ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : confirm_customer_info}
            </a>
          </div>
        ) : null}
      </div>
      {identification_code.uuid && !is_customer_identified ? renderBookingCode() : null}
      {!_is_customer_found() && is_customer_identified ? renderNewCustomerFields() : null}
      {_is_all_fields_filled() && is_customer_identified ? (
        <div className="centerize">
          <a href="#" className="btn btn-tarco find-customer" onClick={createCustomer} disabled={is_creating_customer || !_is_all_fields_filled()}>
            {is_creating_customer? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : confirm_customer_info}
          </a>
        </div>
      ) : null}
    </>
  )

}

export default CustomerIdentification;
