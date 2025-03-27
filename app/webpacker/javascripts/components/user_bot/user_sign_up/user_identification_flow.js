"use strict";

import React, { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import PhoneInput from 'react-phone-input-2'
import TextareaAutosize from 'react-autosize-textarea';

import { IdentificationCodesServices, UsersServices } from "user_bot/api";
import I18n from 'i18n-js/index.js.erb';

import { ErrorMessage, RequiredLabel } from "shared/components";

export const UserIdentificationFlow = ({props, finalView, next}) => {
  const phone_countries = ['jp', 'ca', 'us', 'mx', 'in', 'ru', 'id', 'cn', 'hk', 'kr', 'my', 'sg', 'tw', 'tr', 'fr', 'de', 'it', 'dk', 'fi', 'is', 'uk', 'ar', 'br', 'au', 'nz']
  const {
    page_title, trial_info_html, name, last_name, first_name, confirm_customer_info, booking_code, message,
    phonetic_name, phonetic_last_name, phonetic_first_name, create_customer_info, referral_code_title, referral_code_placeholder, sms_faq
  } = props.i18n.user_sign_up;
  const { confirm, required_label } = props.i18n;

  const { register, handleSubmit, watch, setValue, clearErrors, setError, errors, formState } = useForm({
    defaultValues: {
      phone_number: props.phone_number
    }
  });
  const { isSubmitting } = formState;
  const [is_phone_identified, setPhoneIdentified] = useState(!!props.is_user_logged_in)
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
          <RequiredLabel label={props.i18n.user_sign_up.phone_number} required_label={required_label} />
        </h4>
        <PhoneInput
          country={phone_countries.includes(props.locale) ? props.locale : 'jp'}
          onlyCountries={phone_countries}
          value={phone_number}
          onChange={ (phone) => setValue("phone_number", phone) }
          autoFormat={false}
          placeholder='09012345678'
        />
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
