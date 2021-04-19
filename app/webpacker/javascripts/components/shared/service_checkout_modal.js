"use strict";

import React, { useState } from 'react';
import Popup from 'reactjs-popup';

import StripeCheckoutForm from "shared/stripe_checkout_form"
import { SaleServices } from "user_bot/api";
import ProcessingBar from "shared/processing_bar";
import I18n from 'i18n-js/index.js.erb';

const ServiceCheckoutModal = ({stripe_key, purcahse_data, company_name, service_name, price}) => {
  const [processing, setProcessing] = useState(false)

  const handleToken = async (token) => {
    setProcessing(true)
    const [error, response] = await SaleServices.purchase({ data: {...purcahse_data, token}})
    setProcessing(false)

    window.location = response.data.redirect_to;
  }

  const handleFailure = (error) => {
    console.log(error.message);
  }

  return (
    <Popup
      trigger={<></>}
      open={true}
      modal
      >
        <div>
          <StripeCheckoutForm
            stripe_key={stripe_key}
            handleToken={handleToken}
            handleFailure={handleFailure}
            header={company_name}
            desc={service_name}
            pay_btn={I18n.t("action.pay")}
            details_desc={price}
          />
        </div>
    </Popup>
  )
}

export default ServiceCheckoutModal;
