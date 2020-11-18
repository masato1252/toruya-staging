"use strict";

import React from "react";
import {loadStripe} from '@stripe/stripe-js';
import {
  Elements,
} from '@stripe/react-stripe-js';

import CheckoutForm from "shared/checkout_form";

const StripeCheckoutForm = ({stripe_key, ...rest}) => {
  const stripePromise = loadStripe(stripe_key);

  return (
    <Elements stripe={stripePromise}>
      <CheckoutForm {...rest} />
    </Elements>
  )
}

export default StripeCheckoutForm
