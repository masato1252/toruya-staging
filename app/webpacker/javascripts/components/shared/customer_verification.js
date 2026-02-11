import React from "react";

import I18n from 'i18n-js/index.js.erb';

import { ErrorMessage } from "shared/components";

// 国番号の定数
const COUNTRY_CODES = [
  { code: '+81', label: '🇯🇵 日本', country: 'JP' },
  { code: '+1', label: '🇺🇸 アメリカ', country: 'US' },
  { code: '+86', label: '🇨🇳 中国', country: 'CN' },
  { code: '+82', label: '🇰🇷 韓国', country: 'KR' },
  { code: '+886', label: '🇹🇼 台湾', country: 'TW' },
  { code: '+852', label: '🇭🇰 香港', country: 'HK' },
  { code: '+65', label: '🇸🇬 シンガポール', country: 'SG' },
  { code: '+66', label: '🇹🇭 タイ', country: 'TH' },
  { code: '+84', label: '🇻🇳 ベトナム', country: 'VN' },
  { code: '+63', label: '🇵🇭 フィリピン', country: 'PH' },
  { code: '+44', label: '🇬🇧 イギリス', country: 'GB' },
  { code: '+33', label: '🇫🇷 フランス', country: 'FR' },
  { code: '+49', label: '🇩🇪 ドイツ', country: 'DE' },
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
  locale,
  isEmailRequired = true // デフォルトは必須
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
        {I18n.t("common.name")} <span className="required-label">必須項目</span>
      </h4>
      <div style={{ display: 'flex', gap: '10px' }}>
        <div style={{ flex: 1 }}>
          <input
            name="customer_last_name"
            type="text"
            placeholder={I18n.t("common.last_name")}
            value={customer_last_name || ""}
            onChange={(e) => handleChange('customer_last_name', e.target.value)}
            style={{ width: '100%' }}
          />
          <ErrorMessage error={customer_last_name_failed_message} />
        </div>
        <div style={{ flex: 1 }}>
          <input
            name="customer_first_name"
            type="text"
            placeholder={I18n.t("common.first_name")}
            value={customer_first_name || ""}
            onChange={(e) => handleChange('customer_first_name', e.target.value)}
            style={{ width: '100%' }}
          />
          <ErrorMessage error={customer_first_name_failed_message} />
        </div>
      </div>

      {support_phonetic_name && (
        <>
          <br />
          <div style={{ display: 'flex', gap: '10px' }}>
            <div style={{ flex: 1 }}>
              <input
                id="customer_phonetic_last_name"
                name="customer_phonetic_last_name"
                type="text"
                placeholder={I18n.t("common.phonetic_last_name")}
                value={customer_phonetic_last_name || ""}
                onChange={(e) => handleChange('customer_phonetic_last_name', e.target.value)}
                style={{ width: '100%' }}
              />
            </div>
            <div style={{ flex: 1 }}>
              <input
                id="customer_phonetic_first_name"
                name="customer_phonetic_first_name"
                type="text"
                placeholder={I18n.t("common.phonetic_first_name")}
                value={customer_phonetic_first_name || ""}
                onChange={(e) => handleChange('customer_phonetic_first_name', e.target.value)}
                style={{ width: '100%' }}
              />
            </div>
          </div>
          <ErrorMessage error={customer_phonetic_name_failed_message} />
        </>
      )}

      <h4>
        {I18n.t("common.email")}
        {isEmailRequired && <span className="required-label">必須項目</span>}
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
  // 電話番号から国番号を分離
  const separatePhoneNumber = (phoneNumber) => {
    if (!phoneNumber) return { countryCode: '+81', number: '' };
    
    const phoneStr = String(phoneNumber);
    
    // 国番号を探す
    for (const country of COUNTRY_CODES) {
      if (phoneStr.startsWith(country.code)) {
        return {
          countryCode: country.code,
          number: phoneStr.substring(country.code.length)
        };
      }
    }
    
    // 国番号が見つからない場合、デフォルトは+81
    return { countryCode: '+81', number: phoneStr };
  };
  
  const { countryCode: initialCountryCode, number: initialNumber } = separatePhoneNumber(customer_phone_number);
  const defaultCountryCode = customer_country_code || initialCountryCode;
  const displayPhoneNumber = initialNumber;
  
  return (
    <div className="customer-type-options">
      <h4>
        {I18n.t("common.cellphone_number")} <span className="required-label">必須項目</span>
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
          value={displayPhoneNumber || ""}
          onChange={(e) => handleChange('customer_phone_number', e.target.value)}
          placeholder="9012345678"
        />
      </div>

      <div className="centerize" style={{ marginTop: '20px' }}>
        <a
          href="#"
          className="btn btn-tarco submit"
          onClick={handleSubmit}
          disabled={isSubmitting || !displayPhoneNumber}
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
  isEmailRequired = true, // デフォルトは必須
}) => {
  // 電話番号から国番号を分離
  const separatePhoneNumber = (phoneNumber) => {
    if (!phoneNumber) return { countryCode: '+81', number: '' };
    
    const phoneStr = String(phoneNumber);
    
    // 国番号を探す
    for (const country of COUNTRY_CODES) {
      if (phoneStr.startsWith(country.code)) {
        return {
          countryCode: country.code,
          number: phoneStr.substring(country.code.length)
        };
      }
    }
    
    // 国番号が見つからない場合、デフォルトは+81
    return { countryCode: '+81', number: phoneStr };
  };
  
  const { countryCode: initialCountryCode, number: initialNumber } = separatePhoneNumber(customer_phone_number);
  const defaultCountryCode = customer_country_code || initialCountryCode;
  const displayPhoneNumber = initialNumber;
  
  return (
    <div className="customer-type-options">
      <h4>
        {I18n.t("common.name")} <span className="required-label">必須項目</span>
      </h4>
      <div style={{ display: 'flex', gap: '10px' }}>
        <div style={{ flex: 1 }}>
          <input
            name="customer_last_name"
            type="text"
            placeholder={I18n.t("common.last_name")}
            value={customer_last_name || ""}
            onChange={(e) => handleChange('customer_last_name', e.target.value)}
            style={{ width: '100%' }}
          />
          <ErrorMessage error={errors?.customer_last_name_failed_message} />
        </div>
        <div style={{ flex: 1 }}>
          <input
            name="customer_first_name"
            type="text"
            placeholder={I18n.t("common.first_name")}
            value={customer_first_name || ""}
            onChange={(e) => handleChange('customer_first_name', e.target.value)}
            style={{ width: '100%' }}
          />
          <ErrorMessage error={errors?.customer_first_name_failed_message} />
        </div>
      </div>

      {support_phonetic_name && (
        <>
          <br />
          <div style={{ display: 'flex', gap: '10px' }}>
            <div style={{ flex: 1 }}>
              <input
                id="customer_phonetic_last_name"
                name="customer_phonetic_last_name"
                type="text"
                placeholder={I18n.t("common.phonetic_last_name")}
                value={customer_phonetic_last_name || ""}
                onChange={(e) => handleChange('customer_phonetic_last_name', e.target.value)}
                style={{ width: '100%' }}
              />
            </div>
            <div style={{ flex: 1 }}>
              <input
                id="customer_phonetic_first_name"
                name="customer_phonetic_first_name"
                type="text"
                placeholder={I18n.t("common.phonetic_first_name")}
                value={customer_phonetic_first_name || ""}
                onChange={(e) => handleChange('customer_phonetic_first_name', e.target.value)}
                style={{ width: '100%' }}
              />
            </div>
          </div>
          <ErrorMessage error={errors?.customer_phonetic_name_failed_message} />
        </>
      )}

      <h4>
        {I18n.t("common.cellphone_number")} <span className="required-label">必須項目</span>
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
          value={displayPhoneNumber || ""}
          onChange={(e) => handleChange('customer_phone_number', e.target.value)}
          placeholder="09012345678"
        />
      </div>
      <ErrorMessage error={errors?.customer_phone_number_failed_message} />

      <h4>
        {I18n.t("common.email_address")}
        {isEmailRequired && <span className="required-label">必須項目</span>}
      </h4>
      <input
        type="email"
        className="form-control"
        value={customer_email || ""}
        onChange={(e) => handleChange('customer_email', e.target.value)}
        placeholder="example@example.com"
      />
      <ErrorMessage error={errors?.customer_email_failed_message} />

      <div className="centerize" style={{ marginTop: '20px' }}>
        <a
          href="#"
          className="btn btn-tarco submit"
          onClick={handleSubmit}
          disabled={isSubmitting || !customer_last_name || !customer_first_name || !displayPhoneNumber || (isEmailRequired && !customer_email)}
        >
          {isSubmitting ?
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> :
            (I18n.t("action.complete"))}
        </a>
      </div>
    </div>
  );
};
