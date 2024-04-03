// Dependencies
import * as React from 'react';
import { CreditCard, PaymentForm } from 'react-square-web-payments-sdk';

const SquareCheckoutForm = ({ square_app_id, square_location_id, handleToken, header, desc, details_desc, pay_btn }) => (
  <div className="credit-card">
    <header>
      <h1>{header}</h1>
      <h2>{desc}</h2>
    </header>
    <div className="details">
      {details_desc}
    </div>
    <PaymentForm
      /**
       * Identifies the calling form with a verified application ID generated from
       * the Square Application Dashboard.
       */
      applicationId={square_app_id}
      /**
       * Invoked when payment form receives the result of a tokenize generation
       * request. The result will be a valid credit card or wallet token, or an error.
       */
      cardTokenizeResponseReceived={(token, buyer) => {
        handleToken(token, buyer)
      }}
      /**
       * Identifies the location of the merchant that is taking the payment.
       * Obtained from the Square Application Dashboard - Locations tab.
       */
      locationId={square_location_id}
    >
      <CreditCard
        render={(Button) => <Button>{pay_btn}</Button>}
      />
    </PaymentForm>
  </div>
);

export default SquareCheckoutForm;
