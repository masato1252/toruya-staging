import React, { useState } from "react";

import StripeCheckoutForm from "shared/stripe_checkout_form"
import { PaymentServices } from "components/user_bot/api"
import ProcessingBar from "shared/processing_bar";
import ChargeFailedModal from "components/management/plans/charge_failed";

const StripeCheckoutModal = ({plan_key, rank, props, ...rest}) => {
  const [processing, setProcessing] = useState(false)

  const handleToken = async (token) => {
    setProcessing(true)
    const [error, response] = await PaymentServices.payPlan({token: token, plan: plan_key, rank})
    setProcessing(false)

    if (error) {
      $("#charge-failed-modal").modal("show");
    }
    else {
      window.location = response.data["redirect_path"];
    }
  }

  const handleFailed = (error) => {
    console.log(error.message);
  }

  return (
    <>
    <div className="modal fade" id="checkout-modal" tabIndex="-1" role="dialog">
      <ProcessingBar processing={processing} />
      <div className="modal-content">
        <StripeCheckoutForm handleToken={handleToken} {...rest} />
      </div>
    </div>
    <ChargeFailedModal
      {...props}
    />
    </>
  )
}

export default StripeCheckoutModal
