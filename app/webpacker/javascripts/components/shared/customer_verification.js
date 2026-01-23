import React from "react";

import I18n from 'i18n-js/index.js.erb';

import { ErrorMessage } from "shared/components";

// 国番号の定数
const COUNTRY_CODES = [
  { code: '+81', label: '🇯🇵 日本 (+81)', country: 'JP' },
  { code: '+1', label: '🇺🇸 アメリカ (+1)', country: 'US' },
  { code: '+86', label: '🇨🇳 中国 (+86)', country: 'CN' },
  { code: '+82', label: '🇰🇷 韓国 (+82)', country: 'KR' },
  { code: '+886', label: '🇹🇼 台湾 (+886)', country: 'TW' },
  { code: '+852', label: '🇭🇰 香港 (+852)', country: 'HK' },
  { code: '+65', label: '🇸🇬 シンガポール (+65)', country: 'SG' },
  { code: '+66', label: '🇹🇭 タイ (+66)', country: 'TH' },
  { code: '+84', label: '🇻🇳 ベトナム (+84)', country: 'VN' },
  { code: '+63', label: '🇵🇭 フィリピン (+63)', country: 'PH' },
  { code: '+44', label: '🇬🇧 イギリス (+44)', country: 'GB' },
  { code: '+33', label: '🇫🇷 フランス (+33)', country: 'FR' },
  { code: '+49', label: '🇩🇪 ドイツ (+49)', country: 'DE' },
];

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
        {I18n.t("common.email")} <span className="required">*</span>
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
  customer_country_code,
  handleChange,
  handleSubmit,
  isSubmitting,
}) => {
  const defaultCountryCode = customer_country_code || '+81';
  
  return (
    <div className="customer-type-options">
      <h4>
        {I18n.t("common.phone_number")} <span className="required">*</span>
      </h4>
      <div style={{ display: 'flex', gap: '8px' }}>
        <select
          className="form-control"
          style={{ width: '180px', flexShrink: 0 }}
          value={defaultCountryCode}
          onChange={(e) => handleChange('customer_country_code', e.target.value)}
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
          value={customer_phone_number || ""}
          onChange={(e) => handleChange('customer_phone_number', e.target.value)}
          placeholder="9012345678"
        />
      </div>

      <div className="centerize" style={{ marginTop: '20px' }}>
        <a
          href="#"
          className="btn btn-tarco submit"
          onClick={handleSubmit}
          disabled={isSubmitting || !customer_phone_number}
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
  customer_country_code,
  support_phonetic_name,
  handleChange,
  handleSubmit,
  isSubmitting,
  errors,
}) => {
  const defaultCountryCode = customer_country_code || '+81';
  
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
        {I18n.t("common.email")} <span className="required">*</span>
      </h4>
      <input
        type="email"
        className="form-control"
        value={customer_email || ""}
        onChange={(e) => handleChange('customer_email', e.target.value)}
        placeholder="example@example.com"
      />
      <ErrorMessage error={errors?.customer_email_failed_message} />

      <h4>
        {I18n.t("common.phone_number")} <span className="required">*</span>
      </h4>
      <div style={{ display: 'flex', gap: '8px' }}>
        <select
          className="form-control"
          style={{ width: '180px', flexShrink: 0 }}
          value={defaultCountryCode}
          onChange={(e) => handleChange('customer_country_code', e.target.value)}
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
          value={customer_phone_number || ""}
          onChange={(e) => handleChange('customer_phone_number', e.target.value)}
          placeholder="9012345678"
        />
      </div>

      <div className="centerize" style={{ marginTop: '20px' }}>
        <a
          href="#"
          className="btn btn-tarco submit"
          onClick={handleSubmit}
          disabled={isSubmitting || !customer_last_name || !customer_first_name || !customer_email || !customer_phone_number}
        >
          {isSubmitting ?
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> :
            (I18n.t("action.complete"))}
        </a>
      </div>
    </div>
  );
};
