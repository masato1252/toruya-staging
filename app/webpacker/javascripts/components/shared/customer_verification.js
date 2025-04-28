import React from "react";
import PhoneInput from 'react-phone-input-2';

import I18n from 'i18n-js/index.js.erb';

import { ErrorMessage } from "shared/components";

// Basic information form
export const CustomerBasicInfoForm = ({
  customer_last_name,
  customer_first_name,
  customer_phonetic_last_name,
  customer_phonetic_first_name,
  customer_email,
  errors,
  support_phonetic_name,
  handleChange,
  isSubmitting,
  handleVerifyIdentity,
  verificationError,
  isEmailVerified,
  isBasicInfoValid,
  verificationStep,
  locale
}) => {
  const {
    customer_phonetic_name_failed_message,
    customer_last_name_failed_message,
    customer_first_name_failed_message,
    customer_email_failed_message
  } = errors || {};

  // Determine if the verify button should be shown
  const shouldShowVerifyButton = !isEmailVerified && verificationStep !== 'verification_code';

  return (
    <div className="customer-type-options">
      <h4>
        {I18n.t("common.name")}
      </h4>
      <div>
        <input
          name="customer_last_name"
          type="text"
          placeholder={I18n.t("common.last_name")}
          value={customer_last_name || ""}
          onChange={(e) => handleChange('customer_last_name', e.target.value)}
        />
        <ErrorMessage error={customer_last_name_failed_message} />
        <input
          name="customer_first_name"
          type="text"
          placeholder={I18n.t("common.first_name")}
          value={customer_first_name || ""}
          onChange={(e) => handleChange('customer_first_name', e.target.value)}
        />
        <ErrorMessage error={customer_first_name_failed_message} />
      </div>

      {support_phonetic_name && (
        <>
          <br />
          <div>
            <input
              id="customer_phonetic_last_name"
              name="customer_phonetic_last_name"
              type="text"
              placeholder={I18n.t("common.phonetic_last_name")}
              value={customer_phonetic_last_name || ""}
              onChange={(e) => handleChange('customer_phonetic_last_name', e.target.value)}
            />
            <p></p>
            <input
              id="customer_phonetic_first_name"
              name="customer_phonetic_first_name"
              type="text"
              placeholder={I18n.t("common.phonetic_first_name")}
              value={customer_phonetic_first_name || ""}
              onChange={(e) => handleChange('customer_phonetic_first_name', e.target.value)}
            />
            <ErrorMessage error={customer_phonetic_name_failed_message} />
          </div>
        </>
      )}

      <h4>
        {I18n.t("common.email")}{I18n.t("common.why_need_email")}
      </h4>
      <input
        type="email"
        className="form-control"
        value={customer_email || ""}
        onChange={(e) => handleChange('customer_email', e.target.value)}
        placeholder="example@example.com"
      />
      <ErrorMessage error={customer_email_failed_message} />
      {verificationError && <div className="danger">{verificationError}</div>}

      <div className="centerize mt-2">
        {shouldShowVerifyButton && (
          <a
            href="#"
            className="btn btn-tarco verify-customer"
            onClick={handleVerifyIdentity}
            disabled={isSubmitting || (isBasicInfoValid && !isBasicInfoValid())}
          >
            {isSubmitting ?
              <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> :
              (I18n.t("action.verify_identity"))}
          </a>
        )}
        {isEmailVerified && (
          <span className="email-verified">
            <i className="fa fa-check-circle"></i> {I18n.t("common.email_verified")}
          </span>
        )}
      </div>
    </div>
  );
};

// Verification code form
export const VerificationCodeForm = ({
  verificationCode,
  setVerificationCode,
  verificationError,
  handleVerifyCode,
  handleResendCode,
  handleBack,
  isSubmitting,
}) => {
  return (
    <div className="customer-type-options">
      <h4>{I18n.t("common.verification_code")}</h4>
      <div className="centerize">
        <div className="desc">
          {I18n.t("common.please_enter_verification_code")}
        </div>
        <input
          className="booking-code"
          placeholder="012345"
          type="tel"
          value={verificationCode}
          onChange={(e) => setVerificationCode(e.target.value)}
        />
        {verificationError && <div className="danger">{verificationError}</div>}

        <button onClick={handleVerifyCode} className="btn btn-tarco" disabled={isSubmitting}>
          {isSubmitting ?
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> :
            (I18n.t("action.confirm"))}
        </button>

        <div className="resend-row">
          <a href="#" onClick={handleResendCode}>
            {I18n.t("common.resend_code")}
          </a>
        </div>
      </div>
    </div>
  );
};

// Verified customer form
export const VerifiedCustomerForm = ({
  customer_phone_number,
  handleChange,
  handleSubmit,
  isSubmitting,
}) => {
  const phone_countries = ['jp', 'ca', 'us', 'mx', 'in', 'ru', 'id', 'cn', 'hk', 'kr', 'my', 'sg', 'tw', 'tr', 'fr', 'de', 'it', 'dk', 'fi', 'is', 'uk', 'ar', 'br', 'au', 'nz'];

  return (
    <div className="customer-type-options">
      <h4>
        {I18n.t("common.phone_number")}
      </h4>
      <PhoneInput
        country={phone_countries.includes(I18n.locale) ? I18n.locale : 'jp'}
        onlyCountries={phone_countries}
        value={customer_phone_number || ""}
        onChange={(phone) => handleChange('customer_phone_number', phone)}
        autoFormat={false}
        placeholder="09012345678"
        countryCodeEditable={false}
      />

      <div className="centerize">
        <a
          href="#"
          className="btn btn-tarco submit"
          onClick={handleSubmit}
          disabled={isSubmitting}
        >
          {isSubmitting ?
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> :
            (I18n.t("action.complete"))}
        </a>
      </div>
    </div>
  );
};

export const CustomerInfoForm = ({
  customer_last_name,
  customer_first_name,
  customer_phonetic_last_name,
  customer_phonetic_first_name,
  customer_email,
  customer_phone_number,
  support_phonetic_name,
  handleChange,
  handleSubmit,
  isSubmitting,
  errors,
}) => {
  const phone_countries = ['jp', 'ca', 'us', 'mx', 'in', 'ru', 'id', 'cn', 'hk', 'kr', 'my', 'sg', 'tw', 'tr', 'fr', 'de', 'it', 'dk', 'fi', 'is', 'uk', 'ar', 'br', 'au', 'nz'];

  return (
    <div className="customer-type-options">
      <h4>
        {I18n.t("common.name")}
      </h4>
      <div>
        <input
          name="customer_last_name"
          type="text"
          placeholder={I18n.t("common.last_name")}
          value={customer_last_name || ""}
          onChange={(e) => handleChange('customer_last_name', e.target.value)}
        />
        <ErrorMessage error={errors?.customer_last_name_failed_message} />
        <input
          name="customer_first_name"
          type="text"
          placeholder={I18n.t("common.first_name")}
          value={customer_first_name || ""}
          onChange={(e) => handleChange('customer_first_name', e.target.value)}
        />
        <ErrorMessage error={errors?.customer_first_name_failed_message} />
      </div>

      {support_phonetic_name && (
        <>
          <br />
          <div>
            <input
              id="customer_phonetic_last_name"
              name="customer_phonetic_last_name"
              type="text"
              placeholder={I18n.t("common.phonetic_last_name")}
              value={customer_phonetic_last_name || ""}
              onChange={(e) => handleChange('customer_phonetic_last_name', e.target.value)}
            />
            <p></p>
            <input
              id="customer_phonetic_first_name"
              name="customer_phonetic_first_name"
              type="text"
              placeholder={I18n.t("common.phonetic_first_name")}
              value={customer_phonetic_first_name || ""}
              onChange={(e) => handleChange('customer_phonetic_first_name', e.target.value)}
            />
            <ErrorMessage error={errors?.customer_phonetic_name_failed_message} />
          </div>
        </>
      )}

      <h4>
        {I18n.t("common.email")}{I18n.t("common.why_need_email")}
      </h4>
      <input
        type="email"
        className="form-control"
        value={customer_email || ""}
        onChange={(e) => handleChange('customer_email', e.target.value)}
        placeholder="example@example.com"
      />

      <h4>
        {I18n.t("common.phone_number")}
      </h4>
      <PhoneInput
        country={phone_countries.includes(I18n.locale) ? I18n.locale : 'jp'}
        onlyCountries={phone_countries}
        value={customer_phone_number || ""}
        onChange={(phone) => handleChange('customer_phone_number', phone)}
        autoFormat={false}
        placeholder="09012345678"
        countryCodeEditable={false}
      />

      <div className="centerize">
        <a
          href="#"
          className="btn btn-tarco submit"
          onClick={handleSubmit}
          disabled={isSubmitting || !customer_last_name || !customer_first_name }
        >
          {isSubmitting ?
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> :
            (I18n.t("action.complete"))}
        </a>
      </div>
    </div>
  );
};
