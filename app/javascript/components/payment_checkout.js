"use strict";
import React from "react";
import StripeCheckout from 'react-stripe-checkout';
import "./shared/processing_bar.js";

UI.define("PaymentCheckout", function() {
  return class PaymentCheckout extends React.Component {
    state = {
      processing: false
    }

    toggleProcessing = () => {
      this.setState(prevState => ({ processing: !prevState.processing }));
    }

    onToken = (token) => {
      this.toggleProcessing()

      // modal popup processing
      fetch(this.props.paymentPath, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: "same-origin",
        body: JSON.stringify({
          token: token.id,
          authenticity_token: this.props.formAuthenticityToken
        }),
      }).then((response) => {
        if (response.ok) {
          this.toggleProcessing()
          alert(`We are in business`);
          return;
        // this.props.paymentSuccessHandler()
        }

        if (response.status == 422) {
          return response.json().then(err => { throw err });
        }

        throw Error("Payment failed");
      }).catch((err) => {
        this.toggleProcessing()
        alert(err.message);
        // call failure handler, like show some error message
        // this.props.paymentFailedHandler()
      });
    }

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
          <UI.ProcessingBar processing={this.state.processing} processingMessage={this.props.processingMessage} />
          <button className="btn btn-orange" rel="nofollow">
            Pay this plan
          </button>
        </StripeCheckout>
      )
    }
  };
});

export default UI.PaymentCheckout;
