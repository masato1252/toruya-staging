"use strict";

import React, { useState } from "react";
import { loadStripe } from "@stripe/stripe-js";

import StripeCheckoutForm from "shared/stripe_checkout_form"
import SquareCheckoutForm from "shared/square_checkout_form"
import ProcessingBar from "shared/processing_bar";

const isSetupIntent = (data) =>
  !!(data.setup_intent_id) || (data.client_secret && data.client_secret.startsWith('seti_'));

const ChargingView = ({booking_details, payment_solution, handleTokenCallback, product_name, product_price, business_owner_id, is_subscription = false}) => {
  const [processing, setProcessing] = useState(false)

  const handleRequiresAction = async (actionData, paymentMethodId) => {
    const stripe = await loadStripe(payment_solution.stripe_key);

    if (isSetupIntent(actionData)) {
      return stripe.confirmCardSetup(actionData.client_secret, {
        payment_method: paymentMethodId
      });
    }

    return stripe.confirmCardPayment(actionData.client_secret, {
      payment_method: paymentMethodId
    });
  }

  const pollPaymentStatus = async ({ stripeSubscriptionId, paymentIntentId, paymentMethodId }) => {
    try {
      let url, isSubscription;

      if (stripeSubscriptionId) {
        url = `/stripe_payment_status?stripe_subscription_id=${stripeSubscriptionId}&business_owner_id=${business_owner_id}&type=subscription`;
        isSubscription = true;
      } else if (paymentIntentId) {
        url = `/stripe_payment_status?payment_intent_id=${paymentIntentId}&business_owner_id=${business_owner_id}`;
        isSubscription = false;
      } else {
        throw new Error('Either subscriptionId or paymentIntentId must be provided');
      }

      const response = await fetch(url, {
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
            if (isSubscription) {
              return await handleTokenCallback(paymentMethodId, null, stripeSubscriptionId);
            } else {
              return await handleTokenCallback(paymentMethodId, paymentIntentId);
            }
          case 'failed':
            setProcessing(false);
            alert(result.error || (isSubscription ? 'Subscription payment failed' : 'Payment failed'));
            break;
          case 'processing':
            await new Promise(resolve => setTimeout(resolve, 2000));
            return await pollPaymentStatus({ stripeSubscriptionId, paymentIntentId, paymentMethodId });
          case 'requires_action':
          case 'requires_payment_method':
          case 'requires_confirmation':
            {
              const stripe = await loadStripe(payment_solution.stripe_key);
              const actionData = {
                client_secret: result.client_secret,
                stripe_subscription_id: stripeSubscriptionId
              };

              const { error, setupIntent, paymentIntent } = await handleRequiresAction(actionData, paymentMethodId);

              if (error) {
                setProcessing(false);
                alert(error.message || 'Payment verification failed');
              } else if (setupIntent?.status === 'succeeded') {
                return await handleTokenCallback(paymentMethodId, null, null, setupIntent.id);
              } else if (paymentIntent?.status === 'succeeded') {
                setProcessing(false);
                if (isSubscription) {
                  return await handleTokenCallback(paymentMethodId, null, stripeSubscriptionId);
                } else {
                  return await handleTokenCallback(paymentMethodId, paymentIntentId);
                }
              } else {
                await new Promise(resolve => setTimeout(resolve, 2000));
                return await pollPaymentStatus({ stripeSubscriptionId, paymentIntentId, paymentMethodId });
              }
            }
            break;
        }
      } else {
        setProcessing(false);
        alert(isSubscription ? 'Unable to check subscription status' : 'Unable to check payment status');
      }
    } catch (err) {
      setProcessing(false);
      alert(err.message || (stripeSubscriptionId ? 'Subscription payment failed' : 'Payment failed'));
    }
  };

  const handleStripeToken = async (paymentMethodId) => {
    setProcessing(true)

    try {
      let result = await handleTokenCallback(paymentMethodId)
      let iterations = 0
      const maxIterations = 5

      while (result?.requires_action && result.client_secret && iterations < maxIterations) {
        iterations += 1

        const { error, setupIntent, paymentIntent } = await handleRequiresAction(result, paymentMethodId)

        if (error) {
          setProcessing(false)
          alert(error.message || '3DS verification failed')
          return
        }

        if (setupIntent?.status === 'succeeded') {
          result = await handleTokenCallback(paymentMethodId, null, null, setupIntent.id)
        } else if (paymentIntent?.status === 'succeeded') {
          if (is_subscription && result.stripe_subscription_id) {
            result = await pollPaymentStatus({
              stripeSubscriptionId: result.stripe_subscription_id,
              paymentMethodId
            })
            break
          } else {
            result = await handleTokenCallback(paymentMethodId, paymentIntent.id)
          }
        } else if (paymentIntent?.status === 'processing') {
          result = await pollPaymentStatus({
            paymentIntentId: paymentIntent.id,
            paymentMethodId
          })
          break
        } else if (is_subscription && result.stripe_subscription_id) {
          result = await pollPaymentStatus({
            stripeSubscriptionId: result.stripe_subscription_id,
            paymentMethodId
          })
          break
        } else {
          break
        }
      }

      setProcessing(false)
      return result
    }
     catch (error) {
      setProcessing(false)
      alert(error.message || 'Payment failed')
      throw error
    }
  }

  switch (payment_solution.solution) {
    case "stripe_connect":
      return (
        <div className="done-view">
          <ProcessingBar processing={processing} />
          <StripeCheckoutForm
            stripe_key={payment_solution.stripe_key}
            handleToken={handleStripeToken}
            header={product_name}
            desc={booking_details}
            pay_btn={I18n.t("action.pay")}
            details_desc={product_price}
          />
        </div>
      )
    case "square":
      return (
        <div className="done-view">
          <SquareCheckoutForm
            square_app_id={payment_solution.square_app_id}
            square_location_id={payment_solution.square_location_id}
            handleToken={async (token, buyer) => {
              console.info({ token, buyer });
              await handleTokenCallback(token.token)
            }}
            header={product_name}
            desc={booking_details}
            pay_btn={I18n.t("action.pay")}
            details_desc={product_price}
          />
        </div>
      )
  }
}

export default ChargingView;
