import React, { useState } from "react";
import { loadStripe } from "@stripe/stripe-js";

import StripeCheckoutForm from "shared/stripe_checkout_form"
import { PaymentServices } from "components/user_bot/api"
import ProcessingBar from "shared/processing_bar";
import ChargeFailedModal from "components/management/plans/charge_failed";

const StripeCheckoutModal = ({plan_key, rank, props, ...rest}) => {
  const [processing, setProcessing] = useState(false)

  const handleToken = async (paymentMethodId) => {
    setProcessing(true)

    try {
      const [error, response] = await PaymentServices.payPlan({
        token: paymentMethodId,
        plan: plan_key,
        rank,
        business_owner_id: props.business_owner_id
      })
      setProcessing(false)

      if (error) {
        if (error.response?.data?.client_secret) {
          // Handle 3DS authentication case
          const stripe = await loadStripe(props.stripe_key);
          const { error: confirmError, paymentIntent } = await stripe.confirmCardPayment(
            error.response.data.client_secret,
            {
              payment_method: paymentMethodId,
            }
          );

          setProcessing(true)

          if (confirmError) {
            setProcessing(false)
            $("#charge-failed-modal").modal("show");
          }
          else if (paymentIntent.status === 'succeeded') {
            // Payment successful, retry API call
            const [retryError, retryResponse] = await PaymentServices.payPlan({
              token: paymentMethodId,
              plan: plan_key,
              rank,
              business_owner_id: props.business_owner_id,
              payment_intent_id: paymentIntent.id
            });

            if (retryError) {
              setProcessing(false)
              $("#charge-failed-modal").modal("show");
            } else {
              window.location = retryResponse.data["redirect_path"];
            }
          }
          else if (paymentIntent.status === 'processing') {
            // Start polling payment status
            pollPaymentStatus(paymentIntent.id, paymentMethodId);
          }
        } else {
          setProcessing(false)
          $("#charge-failed-modal").modal("show");
        }
      } else {
        window.location = response.data["redirect_path"];
      }
    } catch (err) {
      setProcessing(false);
      $("#charge-failed-modal").modal("show");
    }
  }

  const pollPaymentStatus = async (paymentIntentId, paymentMethodId) => {
    try {
      const response = await fetch(`/stripe_payment_status?payment_intent_id=${paymentIntentId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          "X-Requested-With": "XMLHttpRequest",
        },
        credentials: "same-origin"
      });

      if (response.ok) {
        const result = await response.json();

        switch (result.status) {
          case 'succeeded':
            setProcessing(false);
            const [retryError, retryResponse] = await PaymentServices.payPlan({
              token: paymentMethodId,
              plan: plan_key,
              rank,
              business_owner_id: props.business_owner_id,
              payment_intent_id: paymentIntentId
            });

            if (retryError) {
              $("#charge-failed-modal").modal("show");
            } else {
              window.location = retryResponse.data["redirect_path"];
            }

            break;
          case 'failed':
            setProcessing(false);
            $("#charge-failed-modal").modal("show");
            break;
          case 'processing':
            // Continue polling
            setTimeout(() => pollPaymentStatus(paymentIntentId, paymentMethodId), 2000);
            break;
          case 'requires_action':
            // Handle cases that require additional actions
            const stripe = await loadStripe(props.stripe_key);
            const { error, paymentIntent } = await stripe.handleCardAction(result.client_secret);

            if (error) {
              setProcessing(false);
              $("#charge-failed-modal").modal("show");
            } else if (paymentIntent.status === 'succeeded') {
              setProcessing(false);
              window.location = result.redirect_path;
            } else {
              // Continue polling
              setTimeout(() => pollPaymentStatus(paymentIntentId, paymentMethodId), 2000);
            }
            break;
        }
      } else {
        setProcessing(false);
        $("#charge-failed-modal").modal("show");
      }
    } catch (err) {
      setProcessing(false);
      $("#charge-failed-modal").modal("show");
    }
  };

  const handleFailed = (error) => {
    console.log(error.message);
  }

  return (
    <>
      <div className="modal fade" id="checkout-modal" tabIndex="-1" role="dialog">
        <ProcessingBar processing={processing} />
        <div className="modal-content">
          <StripeCheckoutForm
            handleToken={handleToken}
            handleFailure={handleFailed}
            {...rest}
          />
        </div>
      </div>
      <ChargeFailedModal {...props} />
    </>
  )
}

export default StripeCheckoutModal
