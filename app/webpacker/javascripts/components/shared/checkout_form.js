import React, { useRef, useEffect } from 'react';
import ReactDOM from 'react-dom';
import {loadStripe} from '@stripe/stripe-js';
import {
  CardElement,
  Elements,
  useStripe,
  useElements,
} from '@stripe/react-stripe-js';

const CARD_ELEMENT_OPTIONS = {
  iconStyle: "solid",
  hidePostalCode: true,
  // style: {
  //   base: {
  //     iconColor: "rgb(240, 57, 122)",
  //     color: "rgb(240, 57, 122)",
  //     fontSize: "16px",
  //     fontFamily: '"Open Sans", sans-serif',
  //     fontSmoothing: "antialiased",
  //     "::placeholder": {
  //       color: "#CFD7DF"
  //     }
  //   },
  //   invalid: {
  //     color: "#e5424d",
  //     ":focus": {
  //       color: "#303238"
  //     }
  //   }
  // }
};

const CheckoutForm = ({header, desc, pay_btn, payment_path, handleToken, handleFailure}) => {
  const stripe = useStripe();
  const elements = useElements();

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!stripe || !elements) {
      return;
    }

    const card = elements.getElement(CardElement)
    const result = await stripe.createToken(card);

    if (result.error) {
      handleFailure(result.error)
    } else {
      handleToken(result.token.id)
    }
  };

  return (
    <form onSubmit={handleSubmit} className="credit-card">
      <header>
        <h1>{header}</h1>
        <h2>{desc}</h2>
      </header>
      <CardElement options={CARD_ELEMENT_OPTIONS} />
      <button type="submit" disabled={!stripe} className="btn btn-success btn-extend btn-large">
        {pay_btn}
      </button>
    </form>
  );
};

export default CheckoutForm;
