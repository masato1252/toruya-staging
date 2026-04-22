"use strict";

import React, { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import TextareaAutosize from 'react-autosize-textarea';

import { IdentificationCodesServices, UsersServices } from "user_bot/api";
import I18n from 'i18n-js/index.js.erb';

import { ErrorMessage, RequiredLabel } from "shared/components";
import { COUNTRY_CODES, separatePhoneNumber, toInternationalNumber } from "shared/customer_verification";
import useAddress from "libraries/use_address";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const UserIdentificationFlow = ({props, finalView, next}) => {
  const {
    page_title, trial_info_html, name, last_name, first_name, confirm_customer_info, booking_code, message,
    phonetic_name, phonetic_last_name, phonetic_first_name, create_customer_info, referral_code_title, referral_code_placeholder, sms_faq
  } = props.i18n.user_sign_up;
  const { confirm, required_label } = props.i18n;

  const { countryCode: initialCountryCode, number: initialLocalPhone } = separatePhoneNumber(props.phone_number, props.locale);
  const [countryCode, setCountryCode] = useState(initialCountryCode);
  const [localPhone, setLocalPhone] = useState(initialLocalPhone);

  const { register, handleSubmit, watch, setValue, clearErrors, setError, errors, formState } = useForm({
    defaultValues: {
      phone_number: props.phone_number ? toInternationalNumber(initialCountryCode, initialLocalPhone) : '',
      email: props.social_user_email || ''
    }
  });
  const { isSubmitting } = formState;
  const [is_phone_identified, setPhoneIdentified] = useState(!!props.is_user_logged_in)
  const watchIsUserMatched = watch("user_id")
  const watchIsIdentificationCodeExists = watch("uuid")
  const watchZipCode = watch("zip_code")
  const personalAddress = useAddress(watchZipCode)

  useEffect(() => {
    setValue("phone_number", toInternationalNumber(countryCode, localPhone));
  }, [countryCode, localPhone]);

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

  useEffect(() => {
    if (personalAddress?.prefecture) setValue("region", personalAddress.prefecture);
    if (personalAddress?.city) setValue("city", personalAddress.city);
  }, [personalAddress.city])


  const generateCode = async (data) => {
    setValue("uuid", "");
    setValue("code", "");
    clearErrors(["code"]);

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
      _.merge(
        {
          staff_token: props.staff_token,
          consultant_token: props.consultant_token,
          locale: props.locale
        },
        _.pick(data, ['phone_number', 'uuid', 'code']
      )
      )
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

  const createUser = async (data) => {
    const [error, response] = await UsersServices.create(
      _.merge(
        {
          staff_token: props.staff_token,
          consultant_token: props.consultant_token,
          locale: props.locale
        },
        data
      )
    );

    if (error) {
      const errResponse = error.response;
      if (errResponse && errResponse.status === 422 && errResponse.data && errResponse.data.errors) {
        const serverErrors = errResponse.data.errors;
        Object.keys(serverErrors).forEach((field) => {
          setError(field, { message: [].concat(serverErrors[field]).join(", ") });
        });
      }
      return;
    }

    const {
      user_id
    } = response.data;

    setValue("user_id", user_id)
  }

  const emailErrorMessage = () => {
    if (!errors.email) return null;
    if (errors.email.type === "pattern") return I18n.t("errors.messages.invalid");
    if (errors.email.message) return errors.email.message;
    return I18n.t("errors.messages.blank");
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
          <RequiredLabel label={I18n.t("common.email")} required_label={required_label} />
        </h4>
        <div className="field">
          <input
            ref={register({ required: true, pattern: EMAIL_REGEX })}
            name="email"
            type="email"
            placeholder={I18n.t("common.email")}
            className={errors.email ? "error" : ""}
          />
          {errors.email && <ErrorMessage error={emailErrorMessage()} />}
        </div>
        <h4>
          <RequiredLabel label={props.i18n.user_sign_up.phone_number} required_label={required_label} />
        </h4>
        <div style={{ display: 'flex', gap: '8px' }}>
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
            value={localPhone}
            onChange={(e) => setLocalPhone(e.target.value)}
            placeholder="09012345678"
          />
        </div>
        <ErrorMessage error={errors.phone_number?.message} />
        {!watchIsIdentificationCodeExists && (
          <div className="centerize margin-around">
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
          <RequiredLabel label={booking_code.code} required_label={required_label} />
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
          {props.support_feature_flags.support_faq_display && (
            <div className="margin-around">
              <a href="https://toruya.com/faq/verification_sms/">
                <i className="fas fa-question-circle"></i> {sms_faq}
              </a>
            </div>
          )}
        </div>
      </div>
    )
  }

  const renderNewCustomerFields = () => {
    if (watchIsUserMatched || !is_phone_identified) return;

    return (
      <div className="customer-type-options">
        {props.support_feature_flags.support_phonetic_name && (
          <>
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
          </>
        )}
        <div className="reminder-mark centerize">
          {I18n.t("user_bot.guest.user_sign_up.personal_address_required_hint")}
        </div>
        <h4>
          <RequiredLabel label={I18n.t("common.zip_code")} required_label={required_label} />
        </h4>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="zip_code"
            placeholder="1234567"
            type="tel"
            className={errors.zip_code ? "error" : ""}
          />
        </div>
        <h4>
          <RequiredLabel label={I18n.t("common.address")} required_label={required_label} />
        </h4>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="region"
            placeholder={I18n.t("common.address_region")}
            type="text"
            className={errors.region ? "error" : ""}
          />
        </div>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="city"
            placeholder={I18n.t("common.address_city")}
            type="text"
            className={`expanded ${errors.city ? "error" : ""}`}
          />
        </div>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="street1"
            placeholder={I18n.t("common.address_street1")}
            type="text"
            className={`expanded ${errors.street1 ? "error" : ""}`}
          />
        </div>
        <div className="field">
          <input
            ref={register()}
            name="street2"
            placeholder={I18n.t("common.address_street2")}
            type="text"
            className="expanded"
          />
        </div>
        <h4>{I18n.t("user_bot.guest.user_sign_up.know_more_about_you")}</h4>
        <div className="field">
          <input
            type="text"
            ref={register()}
            placeholder={I18n.t("user_bot.guest.user_sign_up.where_u_find_toruya")}
            name="where_know_toruya"
          />
          <TextareaAutosize
            ref={register()}
            placeholder={I18n.t("user_bot.guest.user_sign_up.what_you_expect_toruya_solve")}
            name="what_main_problem"
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
      {<input ref={register} name="phone_number" type="hidden" />}
      <h2 className="centerize">
        {page_title}
      </h2>
      {render()}
    </form>
  )

}

export default UserIdentificationFlow;
