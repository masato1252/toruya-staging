"use strict";

import React, { useState } from "react";

import CustomerVerificationForm from "components/shared/customer_verification_form"

export const CustomerIdentification = ({
    social_customer,
    customer,
    i18n,
    support_feature_flags,
    locale,
    identifiedCallback,
    user_id
  }) => {

  const [customer_values, setCustomerValues] = useState({
    customer_id: customer?.customer_id,
    customer_last_name: customer?.customer_last_name,
    customer_first_name: customer?.customer_first_name,
    customer_phonetic_last_name: customer?.customer_phonetic_last_name,
    customer_phonetic_first_name: customer?.customer_phonetic_first_name,
    customer_phone_number: customer?.customer_phone_number,
    customer_email: customer?.customer_email,
    customer_verified: customer?.is_identified,
    user_id: customer?.user_id || '',
    customer_social_user_id: social_customer?.social_user_id || '',
    errors: {}
  });

  if (!!customer_values.customer_id && customer_values.customer_verified) {
    return (
      <div className="whole-page-center final">
        <div dangerouslySetInnerHTML={{ __html: i18n.successful_message_html }} />
      </div>
    )
  }

  return (
    <div className="margin-around">
      <CustomerVerificationForm
        setCustomerValues={setCustomerValues}
        customerValues={customer_values}
        found_customer={customer_values.customer_verified}
        setCustomerFound={({customer_id}) => {
          setCustomerValues(prev => ({
            ...prev,
            customer_id: customer_id,
            customer_verified: true
          }));

          if (identifiedCallback) {
            identifiedCallback({customer_id, customer_verified: true});
          }
        }}
        i18n={i18n}
        support_phonetic_name={support_feature_flags.support_phonetic_name}
        locale={locale || 'en'}
      />
    </div>
  )
}

export default CustomerIdentification;