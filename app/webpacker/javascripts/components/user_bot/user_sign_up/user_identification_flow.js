"use strict";

import React, { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { IdentificationCodesServices, UsersServices } from "user_bot/api";

import { ErrorMessage, RequiredLabel } from "shared/components";

export const UserIdentificationFlow = ({props, finalView, next}) => {
  const {
    page_title, name, last_name, first_name, phone_number, confirm_customer_info, booking_code, message,
    phonetic_name, phonetic_last_name, phonetic_first_name, create_customer_info, referral_code_title, referral_code_placeholder
  } = props.i18n.user_sign_up;
  const { confirm, required_label } = props.i18n;

  const { register, handleSubmit, watch, setValue, clearErrors, setError, errors, formState } = useForm();
  const { isSubmitting } = formState;
  const [is_phone_identified, setPhoneIdentified] = useState(!!props.is_user_logged_in)
  const watchIsUserMatched = watch("user_id")
  const watchIsIdentificationCodeExists = watch("uuid")

  useEffect(() => {
    if (props.is_user_logged_in) {
      next()
    }
  }, [])

  useEffect(() => {
    if (watchIsUserMatched && is_phone_identified) {
      next()
    }
  }, [watchIsUserMatched, is_phone_identified])


  const generateCode = async (data) => {
    setValue("uuid", "");
    setValue("code", "");
    clearErrors(["code"]);

    const [error, response] = await IdentificationCodesServices.create(data);

    setValue("uuid", response.data.uuid)
    setValue("user_id", response.data.user_id)
  }

  const identifyCode = async (data) => {
    clearErrors(["code"])

    const [error, response] = await IdentificationCodesServices.identify(_.pick(data, ['phone_number', 'uuid', 'code']));
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
    const [error, response] = await UsersServices.create(data);
    const {
      user_id
    } = response.data;

    setValue("user_id", user_id)
  }

  const renderUserBasicFields = () => {
    return (
      <div className="customer-type-options">
        <h4>
          <RequiredLabel label={name} required_label={required_label} />
        </h4>
        <div className="field">
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
        </div>
        <h4>
          <RequiredLabel label={phone_number} required_label={required_label} />
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
            ref={register}
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
      <div className="customer-type-options">
        <h4>
          <RequiredLabel label={phonetic_name} required_label={required_label} />
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
          {referral_code_title}
        </h4>
        <div className="field">
          <input
            ref={register()}
            name="referral_token"
            placeholder={referral_code_placeholder}
            type="text"
          />
        </div>
        {is_phone_identified && (
          <div className="centerize">
            <a href="#" className="btn btn-tarco submit" onClick={handleSubmit(createUser)} disabled={isSubmitting}>
              {isSubmitting ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : create_customer_info}
            </a>
          </div>
        )}
      </div>
    )
  }

  const render = () => {
    return (
      <>
        {renderUserBasicFields()}
        {renderIdentificationCode()}
        {renderNewCustomerFields()}
      </>
    )
  }

  return (
    <form>
      {<input ref={register} name="user_id" type="hidden" />}
      {<input ref={register} name="uuid" type="hidden" />}
      <h2 className="centerize">
        {page_title}
      </h2>
      {render()}
    </form>
  )

}

export default UserIdentificationFlow;
