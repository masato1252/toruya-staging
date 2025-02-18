"use strict";

import React, { useState, useEffect } from "react";
import { CustomerVerificationServices } from "components/shared/customer_verification_services";
import {
  CustomerBasicInfoForm,
  VerificationCodeForm,
  VerifiedCustomerForm
} from "components/shared/customer_verification";

const CustomerVerificationForm = ({
  setCustomerValues,
  customerValues,
  found_customer,
  setCustomerFound,
  support_phonetic_name,
  locale
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

  const {
    customer_last_name,
    customer_first_name,
    customer_phonetic_last_name,
    customer_phonetic_first_name,
    customer_phone_number,
    customer_email,
    customer_email_confirmation,
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

  if (found_customer) return <></>;

  // Check if form is valid
  const isBasicInfoValid = () => {
    let isValid = customer_last_name && customer_first_name && customer_phone_number;

    if (support_phonetic_name) {
      isValid = isValid && customer_phonetic_last_name && customer_phonetic_first_name;
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
          customer_last_name_failed_message: !customer_last_name ? i18n.required_field || "Required" : null,
          customer_first_name_failed_message: !customer_first_name ? i18n.required_field || "Required" : null,
          customer_phonetic_name_failed_message: support_phonetic_name && (!customer_phonetic_last_name || !customer_phonetic_first_name) ?
            i18n.required_field || "Required" : null
        }
      }));
      return;
    }

    setIsSubmitting(true);
    setVerificationError(null);

    try {
      const [_error, response] = await CustomerVerificationServices.generateVerificationCode({
        customer_phone_number: customer_phone_number,
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
        customer_phone_number: customer_phone_number,
        uuid: verificationUuid,
        code: verificationCode
      });

      const { verification_successful } = response.data;

      if (verification_successful) {
        setIsPhoneVerified(true);
        setVerificationStep('verified');
        setLastVerifiedPhoneNumber(customer_phone_number);

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

    // Check email match if provided
    if (customer_email && customer_email_confirmation && customer_email !== customer_email_confirmation) {
      // Email mismatch
      return;
    }

    setIsSubmitting(true);

    try {
      const [_error, response] = await CustomerVerificationServices.createOrUpdateCustomer({
        user_id,
        customer_social_user_id,
        customer_last_name,
        customer_first_name,
        customer_phonetic_last_name,
        customer_phonetic_first_name,
        customer_phone_number,
        customer_email,
        uuid: verificationUuid
      });

      if (response.data.customer_id) {
        // Call the setCustomerFound function to proceed with the booking
        setCustomerFound({
          customer_id: response.data.customer_id,
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

  // Common props for CustomerBasicInfoForm
  const commonBasicInfoProps = {
    customer_last_name,
    customer_first_name,
    customer_phonetic_last_name,
    customer_phonetic_first_name,
    customer_phone_number,
    errors: customerValues.errors,
    support_phonetic_name,
    handleChange,
    isSubmitting,
    handleVerifyIdentity: generateVerificationCode,
    verificationError,
    isPhoneVerified,
    isBasicInfoValid,
    verificationStep,
    locale
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
              customer_email={customer_email}
              customer_email_confirmation={customer_email_confirmation}
              handleChange={handleChange}
              handleSubmit={submitVerifiedCustomer}
              isSubmitting={isSubmitting}
            />
          </>
        );
      case 'basic_info':
      default:
        return <CustomerBasicInfoForm {...commonBasicInfoProps} />;
    }
  };

  return renderCurrentStep();
}

export default CustomerVerificationForm;