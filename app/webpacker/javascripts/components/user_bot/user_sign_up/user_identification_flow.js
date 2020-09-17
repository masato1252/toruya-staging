"use strict";

import React, { useState, useRef } from "react";
import Rails from "rails-ujs";
import { useForm } from "react-hook-form";
import axios from "axios";

import { ErrorMessage } from "shared/components";

export const UserIdentificationFlow = ({props, successful_view}) => {
  const {
    name, last_name, first_name, phone_number, confirm_customer_info, booking_code, message, confirm,
    phonetic_name, phonetic_last_name, phonetic_first_name, email, create_customer_info
  } = props.i18n;

  const { register, handleSubmit, watch, setValue, clearErrors, setError, errors, formState } = useForm();
  const { isSubmitting } = formState;
  const [is_phone_identified, setPhoneIdentified] = useState(!!props.social_user.user_id)
  const watchIsUserMatched = watch("user_id")
  const watchIsIdentificationCodeExists = watch("uuid")

  const generateCode = async (data) => {
    setValue("uuid", "");
    setValue("code", "");
    clearErrors(["code"]);

    const response = await axios({
      method: "GET",
      url: props.path.generate_code,
      params: {
        phone_number: data.phone_number
      },
      responseType: "json"
    })

    setValue("uuid", response.data.uuid)
    setValue("user_id", response.data.user_id)
  }

  const identifyCode = async (data) => {
    clearErrors(["code"])

    const response = await axios({
      method: "GET",
      url: props.path.identify_code,
      params: {
        phone_number: data.phone_number,
        uuid: data.uuid,
        code: data.code
      },
      responseType: "json"
    })

    const {
      identification_successful,
    } = response.data;

    setPhoneIdentified(identification_successful)

    if (response.data.errors) {
      setError("code", {
        message: response.data.errors.message
      });
    }
  }

  const createUser = async (data) => {
    const response = await axios({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: props.path.create_user,
      data: {
        first_name: data.first_name,
        last_name: data.last_name,
        phone_number: data.phone_number,
        email: data.email,
        phonetic_last_name: data.phonetic_last_name,
        phonetic_first_name: data.phonetic_first_name,
        uuid: data.uuid
      },
      responseType: "json"
    })

    const {
      user_id
    } = response.data;

    setValue("user_id", user_id)
  }

  const renderUserBasicFields = () => {
    return (
      <div className="customer-type-options">
        <h4>
          {name}
        </h4>
        <input
          ref={register({ required: true })}
          name="last_name"
          placeholder={last_name}
          type="text"
        />
        <input
          ref={register({ required: true })}
          name="first_name"
          placeholder={first_name}
          type="text"
        />
        <h4>
          {phone_number}
        </h4>
        <input
          ref={register({ required: true })}
          name="phone_number"
          placeholder="0123456789"
          type="tel"
        />
        {!watchIsIdentificationCodeExists && (
          <div className="centerize">
            <a href="#" className="btn btn-tarco submit" onClick={handleSubmit(generateCode)} disabled={isSubmitting}>
              {isSubmitting ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : confirm_customer_info}
            </a>
          </div>
        )}
      </div>
    )
  }

  const renderIdentificationCode = () => {
    if (!watchIsIdentificationCodeExists || is_phone_identified) return;

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
            ref={register({ required: true })}
            name="code"
            className="booking-code"
            placeholder="012345"
            type="tel"
          />
          <button
            onClick={handleSubmit(identifyCode)}
            className="btn btn-tarco">
            {confirm}
          </button>
          <ErrorMessage error={errors.code?.message} />
          <div className="resend-row">
            <a href="#" onClick={handleSubmit(generateCode)} >
              {booking_code.resend}
            </a>
          </div>
        </div>
      </div>
    )
  }

  const renderNewCustomerFields = () => {
    if (watchIsUserMatched || !is_phone_identified) return;

    return (
      <>
        <h4>
          {phonetic_name}
        </h4>
        <div className="field">
          <input
            ref={register({ required: true })}
            placeholder={phonetic_last_name}
            type="text"
            name="phonetic_last_name"
          />
          <input
            ref={register({ required: true })}
            placeholder={phonetic_first_name}
            type="text"
            name="phonetic_first_name"
          />
        </div>
        <h4>
          {phonetic_name}
        </h4>
        <div className="field">
          <input
            ref={register}
            placeholder="mail@domail.com"
            type="text"
            name="email"
          />
        </div>
        {is_phone_identified && (
          <div className="centerize">
            <a href="#" className="btn btn-tarco submit" onClick={handleSubmit(createUser)} disabled={isSubmitting}>
              {isSubmitting ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : create_customer_info}
            </a>
          </div>
        )}
      </>
    )
  }

  const render = () => {
    if ((watchIsUserMatched && is_phone_identified) || props.social_user.user_id) {
      return successful_view
    }
    else {
      return (
        <>
          {renderUserBasicFields()}
          {renderIdentificationCode()}
          {renderNewCustomerFields()}
        </>
      )
    }
  }

  return (
    <form onSubmit={handleSubmit(generateCode)}>
      {<input ref={register} name="user_id" type="hidden" />}
      {<input ref={register} name="uuid" type="hidden" />}
      {render()}
    </form>
  )

}

export default UserIdentificationFlow;

