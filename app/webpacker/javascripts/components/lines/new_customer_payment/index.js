"use strict";

import React, { useState } from "react";
import I18n from 'i18n-js/index.js.erb';

import { CommonServices } from "user_bot/api";
import ProcessingBar from "shared/processing_bar";
import StripeCheckoutForm from "shared/stripe_checkout_form"

export const NewCustomerPayment = ({props}) => {
  const [processing, setProcessing] = useState(false)

  const handleToken = async (token) => {
    setProcessing(true)
    const [error, response] = await CommonServices.create({
      url: Routes.customer_payments_path(props.slug, {format: "json"}),
      data: { token, order_id: props.order_id, encrypted_social_service_user_id: props.encrypted_social_service_user_id }
    })
    setProcessing(false)

    if (error) {
      toastr.error(error.response.data.error_message)
    }
    else {
      window.location = response.data.redirect_to;
    }
  }

  const handleFailure = (error) => {
    toastr.error(error.message)
  }

  return (
    <div className="done-view">
      <ProcessingBar processing={processing} />
      <h3 className="title">
        {I18n.t("common.pay_the_payment")}
      </h3>
      <StripeCheckoutForm
        stripe_key={props.stripe_key}
        handleToken={handleToken}
        handleFailure={handleFailure}
        header={props.company_name}
        desc={props.service_name}
        pay_btn={I18n.t("action.pay")}
        details_desc={props.price}
      />
    </div>
  )
}

export default NewCustomerPayment;
