import React, { useState } from 'react';
import {
  CardElement,
  useStripe,
  useElements,
} from '@stripe/react-stripe-js';

const CARD_ELEMENT_OPTIONS = {
  iconStyle: "solid",
  hidePostalCode: true,
  style: {
    base: {
      fontSize: '16px',
      color: '#424770',
      '::placeholder': {
        color: '#aab7c4',
      },
    },
    invalid: {
      color: '#9e2146',
    },
  },
};

const CheckoutForm = ({header, desc, pay_btn, details_desc, handleToken, handleFailure}) => {
  const [processing, setProcessing] = useState(false)
  const stripe = useStripe();
  const elements = useElements();

  const handleSubmit = async (event) => {
    setProcessing(true)
    event.preventDefault();

    if (!stripe || !elements) {
      return;
    }

    const card = elements.getElement(CardElement)
    const {error, paymentMethod} = await stripe.createPaymentMethod({
      type: 'card',
      card: card,
    });

    setProcessing(false);
    if (error) {
      if (handleFailure) handleFailure(error);
    } else {
      await handleToken(paymentMethod.id);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="credit-card">
      <header>
        <h1 dangerouslySetInnerHTML={{__html: header}} />
        <h2>{desc}</h2>
      </header>
      <div className="details">
        {details_desc}
      </div>
      <CardElement options={CARD_ELEMENT_OPTIONS} />
      <button type="submit" disabled={!stripe || processing} className="btn btn-success btn-extend btn-large">
        {pay_btn}
      </button>
    </form>
  );
};

export default CheckoutForm;