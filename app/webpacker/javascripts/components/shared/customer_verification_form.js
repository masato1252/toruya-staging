"use strict";

import React, { useState, useEffect } from "react";
import { CustomerVerificationServices } from "components/shared/customer_verification_services";
import {
  CustomerBasicInfoForm,
  VerificationCodeForm,
  VerifiedCustomerForm,
  CustomerInfoForm,
  toInternationalNumber
} from "components/shared/customer_verification";

const CustomerVerificationForm = ({
  setCustomerValues,
  customerValues,
  found_customer,
  setCustomerFound,
  support_phonetic_name,
  verification_required,
  locale,
  is_free_plan,
  is_trial_member,
  has_customer_line_connection,
  email_always_required
}) => {
  const phone_countries = ['jp', 'ca', 'us', 'mx', 'in', 'ru', 'id', 'cn', 'hk', 'kr', 'my', 'sg', 'tw', 'tr', 'fr', 'de', 'it', 'dk', 'fi', 'is', 'uk', 'ar', 'br', 'au', 'nz'];

  // Verification states
  const [verificationStep, setVerificationStep] = useState('basic_info'); // basic_info, verification_code, verified
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [verificationUuid, setVerificationUuid] = useState('');
  const [verificationCode, setVerificationCode] = useState('');
  const [verificationError, setVerificationError] = useState(null);
  const [isPhoneVerified, setIsPhoneVerified] = useState(false);
  const [lastVerifiedPhoneNumber, setLastVerifiedPhoneNumber] = useState('');
  const [isEmailVerified, setIsEmailVerified] = useState(false);
  const [lastVerifiedEmail, setLastVerifiedEmail] = useState('');

  const {
    customer_last_name,
    customer_first_name,
    customer_phonetic_last_name,
    customer_phonetic_first_name,
    customer_phone_number,
    customer_phone_number_confirmation,
    customer_email,
    customer_country_code,
    customer_id,
    user_id,
    customer_social_user_id
  } = customerValues;

  const {
    customer_phonetic_name_failed_message,
    customer_last_name_failed_message,
    customer_first_name_failed_message
  } = customerValues.errors || {};

  // Effect to reset verification if phone number changes after verification
  useEffect(() => {
    if (isPhoneVerified && lastVerifiedPhoneNumber && customer_phone_number !== lastVerifiedPhoneNumber) {
      // Reset verification state
      setVerificationStep('basic_info');
      setIsPhoneVerified(false);
      setVerificationUuid('');
      setVerificationCode('');
      setVerificationError(I18n.t("common.phone_number_changed_message") || "Phone number has changed. Verification required.");

      // Update form values to indicate not verified
      setCustomerValues(prev => ({
        ...prev,
        is_verified: false
      }));
    }
  }, [customer_phone_number, isPhoneVerified, lastVerifiedPhoneNumber]);

  // Effect to reset verification if email changes after verification
  useEffect(() => {
    if (isEmailVerified && lastVerifiedEmail && customer_email !== lastVerifiedEmail) {
      // Reset verification state
      setVerificationStep('basic_info');
      setIsEmailVerified(false);
      setVerificationUuid('');
      setVerificationCode('');
      setVerificationError(I18n.t("common.email_changed_message") || "Email has changed. Verification required.");

      // Update form values to indicate not verified
      setCustomerValues(prev => ({
        ...prev,
        is_verified: false
      }));
    }
  }, [customer_email, isEmailVerified, lastVerifiedEmail]);

  if (found_customer) return <></>;

  // Check if form is valid (phone number is collected in a later step, so not checked here)
  const isBasicInfoValid = () => {
    let isValid = customer_last_name && customer_first_name;

    if (support_phonetic_name) {
      isValid = isValid && customer_phonetic_last_name && customer_phonetic_first_name;
    }

    if (isEmailRequired()) {
      isValid = isValid && customer_email;
    }

    return isValid;
  };

  // Generate verification code
  const generateVerificationCode = async (e) => {
    e.preventDefault();

    if (!isBasicInfoValid()) {
      setCustomerValues(prev => ({
        ...prev,
        errors: {
          ...prev.errors,
          customer_last_name_failed_message: !customer_last_name ? I18n.t("booking_page.message.customer_last_name_failed_message") || "Required" : null,
          customer_first_name_failed_message: !customer_first_name ? I18n.t("booking_page.message.customer_first_name_failed_message") || "Required" : null,
          customer_phonetic_name_failed_message: support_phonetic_name && (!customer_phonetic_last_name || !customer_phonetic_first_name) ?
            I18n.t("booking_page.message.customer_phonetic_name_failed_message") || "Required" : null
        }
      }));
      return;
    }

    setIsSubmitting(true);
    setVerificationError(null);

    try {
      const [_error, response] = await CustomerVerificationServices.generateVerificationCode({
        customer_email: customer_email,
        user_id: user_id
      });

      if (response.data.uuid) {
        setVerificationUuid(response.data.uuid);
        setVerificationStep('verification_code');
      }

      if (response.data.errors) {
        setVerificationError(response.data.errors.message);
      }
    } catch (exception) {
      setVerificationError("An error occurred. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Verify code
  const verifyCode = async (e) => {
    e.preventDefault();

    if (!verificationCode) {
      setVerificationError(I18n.t("errors.code_required"));
      return;
    }

    setIsSubmitting(true);
    setVerificationError(null);

    try {
      const [_error, response] = await CustomerVerificationServices.verifyCode({
        user_id: user_id,
        customer_email: customer_email,
        customer_id: customer_id,
        uuid: verificationUuid,
        code: verificationCode
      });

      const { verification_successful } = response.data;

      if (verification_successful) {
        setIsEmailVerified(true);
        setVerificationStep('verified');
        setLastVerifiedEmail(customer_email);

        // Update form values to indicate verified
        setCustomerValues(prev => ({
          ...prev,
          is_verified: true
        }));
      }

      if (response.data.errors) {
        setVerificationError(response.data.errors.message);
      }
    } catch (exception) {
      setVerificationError("An error occurred. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Submit verified customer
  const submitVerifiedCustomer = async (e) => {
    e.preventDefault();

    setIsSubmitting(true);

    try {
      // 共通関数でローカル番号を国際番号に変換
      // 例: countryCode='+81', number='09090841258' → '+819090841258'
      const effectiveCountryCode = customer_country_code || '+81';
      const fullPhoneNumber = toInternationalNumber(effectiveCountryCode, customer_phone_number);

      const [_error, response] = await CustomerVerificationServices.createOrUpdateCustomer({
        user_id,
        customer_social_user_id,
        customer_last_name,
        customer_first_name,
        customer_phonetic_last_name,
        customer_phonetic_first_name,
        customer_phone_number: fullPhoneNumber,
        customer_email,
        customer_id,
        uuid: verificationUuid
      });

      if (response.data.customer_id) {
        // stateの電話番号を国際番号形式に更新（後続のhandleSubmitで正しい番号が送られるように）
        setCustomerValues(prev => ({
          ...prev,
          customer_phone_number: fullPhoneNumber
        }));

        // Call the setCustomerFound function to proceed with the booking
        setCustomerFound({
          customer_id: response.data.customer_id,
          customer_verified: true
        });
      }

      if (response.data.errors) {
        setVerificationError(response.data.errors.message);
      }
    } catch (exception) {
      setVerificationError("An error occurred. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle input changes
  const handleChange = (field, value) => {
    setCustomerValues(prev => ({
      ...prev,
      [field]: value
    }));
  };

  // メールアドレスの必須判定
  // 任意：有料プラン（試用期間外） + 顧客LINE連携あり
  // それ以外：必須
  const isEmailRequired = () => {
    if (email_always_required) return true;
    if (is_free_plan) return true;
    if (is_trial_member) return true;
    if (!has_customer_line_connection) return true;
    return false;
  };

  // Common props for CustomerBasicInfoForm
  const commonBasicInfoProps = {
    customer_last_name,
    customer_first_name,
    customer_phonetic_last_name,
    customer_phonetic_first_name,
    customer_email,
    customer_phone_number,
    customer_country_code,
    errors: customerValues.errors,
    support_phonetic_name,
    handleChange,
    isSubmitting,
    handleVerifyIdentity: generateVerificationCode,
    isEmailVerified,
    isBasicInfoValid,
    verificationStep,
    locale,
    isEmailRequired: isEmailRequired()
  };

  // Render component based on current step
  const renderCurrentStep = () => {
    switch(verificationStep) {
      case 'verification_code':
        return (
          <>
            <CustomerBasicInfoForm {...commonBasicInfoProps} />
            <VerificationCodeForm
              verificationCode={verificationCode}
              setVerificationCode={setVerificationCode}
              verificationError={verificationError}
              handleVerifyCode={verifyCode}
              handleResendCode={generateVerificationCode}
              handleBack={() => setVerificationStep('basic_info')}
              isSubmitting={isSubmitting}
            />
          </>
        );
      case 'verified':
        return (
          <>
            <CustomerBasicInfoForm {...commonBasicInfoProps} />
            <VerifiedCustomerForm
              customer_phone_number={customer_phone_number}
              customer_country_code={customer_country_code}
              handleChange={handleChange}
              handleSubmit={submitVerifiedCustomer}
              isSubmitting={isSubmitting}
              locale={locale}
            />
          </>
        );
      case 'basic_info':
      default:
        return <CustomerBasicInfoForm {...commonBasicInfoProps} verificationError={verificationError}/>;
    }
  };

  if (verification_required) {
    return renderCurrentStep();
  } else {
    return <CustomerInfoForm {...commonBasicInfoProps} handleSubmit={submitVerifiedCustomer} isSubmitting={isSubmitting} isEmailRequired={isEmailRequired()} />;
  }
}

export default CustomerVerificationForm;