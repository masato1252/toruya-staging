import React, { useState } from "react";

import StripeCheckoutForm from "shared/stripe_checkout_form"
import { PaymentServices } from "components/user_bot/api"
import ProcessingBar from "shared/processing_bar";
import I18n from 'i18n-js/index.js.erb';

const StripeChangeCardModal = ({props, ...rest}) => {
  const [processing, setProcessing] = useState(false)

  const handleToken = async (token) => {
    setProcessing(true)
    console.log("token", token)
    const [error, response] = await PaymentServices.changeCard({token: token})
    setProcessing(false)

    if (error) {
      alert(I18n.t("common.update_failed_message"));
    }
    else {
      alert(I18n.t("common.update_successfully_message"));

      window.location = response.data["redirect_path"];
    }
  }

  const handleFailed = (error) => {
    console.log(error.message);
  }

  return (
    <>
    <div className="modal fade" id="change-card-modal" tabIndex="-1" role="dialog">
      <ProcessingBar processing={processing} />
      <div className="modal-content">
        <StripeCheckoutForm handleToken={handleToken} {...rest} />
      </div>
    </div>
    </>
  )
}

export default StripeChangeCardModal
