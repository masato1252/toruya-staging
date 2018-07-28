"use strict";
import React from "react";
import StripeCheckout from 'react-stripe-checkout';
import ProcessingBar from "./shared/processing_bar";

class PaymentCheckout extends React.Component {
  state = {
    processing: false
  }

  toggleProcessing = () => {
    this.setState(prevState => ({ processing: !prevState.processing }));
  }

  onToken = async (token) => {
    try {
      this.toggleProcessing()

      // modal popup processing
      const response = await fetch(this.props.paymentPath, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: "same-origin",
        body: JSON.stringify({
          token: token.id,
          authenticity_token: this.props.formAuthenticityToken
        }),
      })

      if (response.ok) {
        const result = await response.json()
        this.toggleProcessing()
        window.location = result["redirect_path"];

      } else if (response.status === 422) {
        response.json().then(err => { throw err });
      } else {
        throw Error("Payment failed");
      }
    }
    catch (err) {
      this.toggleProcessing()
      alert(err.message);
    }
  };

  render() {
    return (
      <StripeCheckout
        token={this.onToken}
        stripeKey={this.props.stripeKey}
        amount={this.props.plan.cost}
        currency="JPY"
        email={this.props.email}
        panelLabel="Pay"
        allowRememberMe={false}
        locale={this.props.locale}
        name="Toruya"
        description={this.props.plan.name}
      >
        <ProcessingBar processing={this.state.processing} processingMessage={this.props.processingMessage} />
        <button className="btn btn-orange" rel="nofollow">
          Pay this plan
        </button>
      </StripeCheckout>
    )
  }
};

export default PaymentCheckout;
