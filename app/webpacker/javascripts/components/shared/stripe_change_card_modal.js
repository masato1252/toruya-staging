import React, { useState } from "react";
import { loadStripe } from "@stripe/stripe-js";

import StripeCheckoutForm from "shared/stripe_checkout_form"
import { PaymentServices, CommonServices } from "components/user_bot/api"
import ProcessingBar from "shared/processing_bar";
import I18n from 'i18n-js/index.js.erb';

const StripeChangeCardModal = ({change_card_path, business_owner_id, ...rest}) => {
  const [processing, setProcessing] = useState(false)

  const handleToken = async (paymentMethodId, paymentIntentId = null) => {
    setProcessing(true)
    try {
      const [error, response] = await CommonServices.update({
        url: change_card_path,
        data: {
          token: paymentMethodId,
          business_owner_id,
          payment_intent_id: paymentIntentId
        }
      })
      setProcessing(false)

      if (error) {
        if (error.response?.data?.client_secret) {
          // Handle cases that require 3DS verification
          const stripe = await loadStripe(rest.stripe_key);
          const { error: confirmError, paymentIntent } = await stripe.confirmCardPayment(
            error.response.data.client_secret,
            {
              payment_method: paymentMethodId
            }
          );

          if (confirmError) {
            alert(I18n.t("common.update_failed_message"));
          } else if (paymentIntent.status === 'succeeded') {
            // Payment successful, retry API call
            const [retryError, retryResponse] = await CommonServices.update({
              url: change_card_path,
              data: {
                token: paymentMethodId,
                business_owner_id,
                payment_intent_id: paymentIntent.id
              }
            });

            if (retryError) {
              alert(I18n.t("common.update_failed_message"));
            } else {
              alert(I18n.t("common.update_successfully_message"));
              window.location = retryResponse.data.redirect_to;
            }
          } else if (paymentIntent.status === 'processing') {
            // Start polling payment status
            pollPaymentStatus(paymentIntent.id);
          }
        } else {
          alert(I18n.t("common.update_failed_message"));
        }
      } else {
        alert(I18n.t("common.update_successfully_message"));
        window.location = response.data.redirect_to;
      }
    } catch (err) {
      setProcessing(false);
      alert(I18n.t("common.update_failed_message"));
    }
  }

  const pollPaymentStatus = async (paymentIntentId) => {
    try {
      const response = await fetch(`/stripe_payment_status?payment_intent_id=${paymentIntentId}&type=change_card`, {
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
            alert(I18n.t("common.update_successfully_message"));
            window.location = result.redirect_path;
            break;
          case 'failed':
            setProcessing(false);
            alert(I18n.t("common.update_failed_message"));
            break;
          case 'processing':
            // Continue polling
            setTimeout(() => pollPaymentStatus(paymentIntentId), 2000);
            break;
          case 'requires_action':
            // Handle cases that require additional actions
            const stripe = await loadStripe(rest.stripe_key);
            const { error, paymentIntent } = await stripe.handleCardAction(result.client_secret);

            if (error) {
              setProcessing(false);
              alert(I18n.t("common.update_failed_message"));
            } else if (paymentIntent.status === 'succeeded') {
              setProcessing(false);
              alert(I18n.t("common.update_successfully_message"));
              window.location = result.redirect_path;
            } else {
              // Continue polling
              setTimeout(() => pollPaymentStatus(paymentIntentId), 2000);
            }
            break;
        }
      } else {
        setProcessing(false);
        alert(I18n.t("common.update_failed_message"));
      }
    } catch (err) {
      setProcessing(false);
      alert(I18n.t("common.update_failed_message"));
    }
  };

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
