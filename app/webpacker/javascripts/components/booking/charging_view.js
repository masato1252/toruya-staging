"use strict";

import React, { useState } from "react";
import { loadStripe } from "@stripe/stripe-js";

import StripeCheckoutForm from "shared/stripe_checkout_form"
import SquareCheckoutForm from "shared/square_checkout_form"
import ProcessingBar from "shared/processing_bar";

const ChargingView = ({booking_details, payment_solution, handleTokenCallback, product_name, product_price, business_owner_id, is_subscription = false}) => {
  const [processing, setProcessing] = useState(false)

  const handleStripeToken = async (paymentMethodId) => {
    setProcessing(true)

    try {
      // First try the normal payment flow
      const result = await handleTokenCallback(paymentMethodId)

      // Check if 3DS verification is needed
      if (result && result.requires_action && result.client_secret) {
        // Handle 3DS verification
        const stripe = await loadStripe(payment_solution.stripe_key);

        if (is_subscription && result.stripe_subscription_id) {
          // Handle subscription 3DS
          const { error: confirmError } = await stripe.confirmCardPayment(result.client_secret);

          if (confirmError) {
            setProcessing(false)
            alert(confirmError.message || '3DS verification failed');
          } else {
            // Start polling subscription status
            return await pollPaymentStatus({ stripeSubscriptionId: result.stripe_subscription_id, paymentMethodId });
          }
        }
        else {
          // Handle payment intent 3DS
          const { error: confirmError, paymentIntent } = await stripe.confirmCardPayment(
            result.client_secret
          );

          if (confirmError) {
            setProcessing(false)
            alert(confirmError.message || '3DS verification failed');
          }
          else if (paymentIntent.status === 'succeeded') {
            // 3DS verification successful, retry payment submission
            const retryResult = await handleTokenCallback(paymentMethodId, paymentIntent.id);
            setProcessing(false)
            return retryResult;
          }
          else if (paymentIntent.status === 'processing') {
            // Start polling payment status
            return await pollPaymentStatus({ paymentIntentId: paymentIntent.id, paymentMethodId });
          }
        }
      }

      setProcessing(false)
      return result;
    }
     catch (error) {
      setProcessing(false)
      throw error;
    }
  }

  const pollPaymentStatus = async ({ stripeSubscriptionId, paymentIntentId, paymentMethodId }) => {
    try {
      let url, type, isSubscription;

      if (stripeSubscriptionId) {
        url = `/stripe_payment_status?stripe_subscription_id=${stripeSubscriptionId}&business_owner_id=${business_owner_id}&type=subscription`;
        type = 'subscription';
        isSubscription = true;
      } else if (paymentIntentId) {
        url = `/stripe_payment_status?payment_intent_id=${paymentIntentId}&business_owner_id=${business_owner_id}`;
        type = 'payment_intent';
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
            alert(isSubscription ? 'Subscription payment failed' : 'Payment failed');
            break;
          case 'processing':
            // Continue polling
            await new Promise(resolve => setTimeout(resolve, 2000));
            return await pollPaymentStatus({ stripeSubscriptionId, paymentIntentId, paymentMethodId });
          case 'requires_action':
            // Handle cases that require additional actions
            const stripe = await loadStripe(payment_solution.stripe_key);

            if (isSubscription) {
              const { error } = await stripe.confirmCardPayment(result.client_secret);
              if (error) {
                setProcessing(false);
                alert(error.message || 'Payment verification failed');
              } else {
                // Continue polling
                await new Promise(resolve => setTimeout(resolve, 2000));
                return await pollPaymentStatus({ stripeSubscriptionId, paymentIntentId, paymentMethodId });
              }
            } else {
              const { error, paymentIntent } = await stripe.handleCardAction(result.client_secret);
              if (error) {
                setProcessing(false);
                alert(error.message || 'Payment verification failed');
              } else if (paymentIntent.status === 'succeeded') {
                setProcessing(false);
                return await handleTokenCallback(paymentMethodId, paymentIntentId);
              } else {
                // Continue polling
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
      alert(err.message || (isSubscription ? 'Subscription payment failed' : 'Payment failed'));
    }
  };

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
