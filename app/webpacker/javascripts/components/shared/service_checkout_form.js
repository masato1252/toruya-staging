"use strict";

import React from 'react';

import StripeCheckoutForm from "shared/stripe_checkout_form"
import { SaleServices } from "user_bot/api";
import I18n from 'i18n-js/index.js.erb';

const ServiceCheckoutForm = ({stripe_key, purcahse_data, company_name, service_name, price, payment_type}) => {
  const handleToken = async (token) => {
    const [error, response] = await SaleServices.purchase({ data: {...purcahse_data, token, payment_type}})

    if (error) {
      toastr.error(error.response.data.error_message)
    }
    else {
      window.location = response.data.redirect_to;
    }
  }

  const handleFailure = (error) => {
    console.log(error.message);
  }

  return (
    <StripeCheckoutForm
      stripe_key={stripe_key}
      handleToken={handleToken}
      handleFailure={handleFailure}
      header={company_name}
      desc={service_name}
      pay_btn={I18n.t("action.pay")}
      details_desc={price}
    />
  )
}

export default ServiceCheckoutForm;
