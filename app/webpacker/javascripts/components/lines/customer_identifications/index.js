"use strict";

import React, { useState } from "react";

import CustomerIdentificationView from "components/lines/customer_identifications/shared/identification_view"

export const CustomerIdentification = (props) => {
  const { successful_message_html } = props.i18n;
  const { social_user_id, customer_id } = props.social_customer;
  const [identified_customer, setIdentifiedCustomer] = useState(customer_id)

  if (identified_customer) {
    return (
      <div className="whole-page-center final">
        <div dangerouslySetInnerHTML={{ __html: successful_message_html }} />
      </div>
    )
  }

  return (
    <CustomerIdentificationView
      social_user_id={social_user_id}
      customer_id={customer_id}
      support_phonetic_name={props.support_feature_flags.support_phonetic_name}
      i18n={props.i18n}
      identifiedCallback={
        (customer) => {
          setIdentifiedCustomer(customer.customer_id)
        }
      }
    />
  )
}

export default CustomerIdentification;
