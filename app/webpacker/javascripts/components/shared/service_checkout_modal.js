"use strict";

import React, { useState } from 'react';
import Popup from 'reactjs-popup';

import StripeCheckoutForm from "shared/stripe_checkout_form"
import { SaleServices } from "user_bot/api";
import ProcessingBar from "shared/processing_bar";

const ServiceCheckoutModal = ({stripe_key, purcahse_data}) => {
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
          <ProcessingBar processing={processing} />
          <StripeCheckoutForm
            stripe_key={stripe_key}
            handleToken={handleToken}
            handleFailure={handleFailure}
            header={"header"}
            desc={"desc"}
            pay_btn={"pay_btn"}
            details_desc={"details_desc"}
          />
        </div>
    </Popup>
  )
}

export default ServiceCheckoutModal;
