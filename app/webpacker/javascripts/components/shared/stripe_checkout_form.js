"use strict";

import React, { useMemo } from "react";
import {loadStripe} from '@stripe/stripe-js';
import {
  Elements,
} from '@stripe/react-stripe-js';

import CheckoutForm from "shared/checkout_form";

const StripeCheckoutForm = ({stripe_key, ...rest}) => {
  const stripePromise = useMemo(() => {
    if (!stripe_key) return null;
    return loadStripe(stripe_key);
  }, [stripe_key]);

  if (!stripePromise) {
    return null; // Stripe is loading
  }

  return (
    <Elements stripe={stripePromise}>
      <CheckoutForm {...rest} />
    </Elements>
  )
}

export default StripeCheckoutForm
