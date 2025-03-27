"use strict";

import React, { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { IdentificationCodesServices, UsersServices } from "user_bot/api";
import PhoneInput from 'react-phone-input-2'

import { ErrorMessage, RequiredLabel } from "shared/components";

export const UserConnect = ({props, next}) => {
  const phone_countries = ['jp', 'ca', 'us', 'mx', 'in', 'ru', 'id', 'cn', 'hk', 'kr', 'my', 'sg', 'tw', 'tr', 'fr', 'de', 'it', 'dk', 'fi', 'is', 'uk', 'ar', 'br', 'au', 'nz']
  const {
    confirm_customer_info, booking_code, message
  } = props.i18n.user_sign_up;
  const {
    page_title
  } = props.i18n.user_connect;
  const { confirm, shop_info, required_label } = props.i18n;

  const { register, handleSubmit, watch, setValue, clearErrors, setError, errors, formState } = useForm();
  const { isSubmitting } = formState;
  const [is_phone_identified, setPhoneIdentified] = useState(false)
  const watchIsUserMatched = watch("user_id")
  const watchIsIdentificationCodeExists = watch("uuid")
  const phone_number = watch("phone_number")

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
    data.login_type = "sign_in"

    const [error, response] = await IdentificationCodesServices.create(data);

    setValue("uuid", response.data?.uuid)
    setValue("user_id", response.data?.user_id)

    if (!response.data.user_id) {
      setError("phone_number", {
        message: response.data.errors.message
      });
    }
  }

  const identifyCode = async (data) => {
    clearErrors(["code"])

    const [error, response] = await IdentificationCodesServices.identify(
      _.pick(data, ['phone_number', 'uuid', 'code'])
    );
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

  const renderUserBasicFields = () => {
    return (
      <div className="customer-type-options">
        <h4>
          <RequiredLabel label={props.i18n.user_sign_up.phone_number} required_label={required_label} />
        </h4>
        <PhoneInput
          country={phone_countries.includes(props.locale) ? props.locale : 'jp'}
          onlyCountries={phone_countries}
          value={phone_number}
          onChange={ (phone) => setValue("phone_number", phone) }
          autoFormat={false}
          placeholder='09012345678'
          countryCodeEditable={false}
        />
        <ErrorMessage error={errors.phone_number?.message} />
        {!watchIsUserMatched && (
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
    if (!watchIsIdentificationCodeExists || is_phone_identified || !watchIsUserMatched) return;

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

  return (
    <form>
      {<input ref={register} name="user_id" type="hidden" />}
      {<input ref={register} name="uuid" type="hidden" />}
      {<input ref={register} name="phone_number" type="hidden" />}
      <h2 className="centerize">
        {page_title}
      </h2>
      {renderUserBasicFields()}
      {renderIdentificationCode()}
    </form>
  )

}

export default UserConnect;
