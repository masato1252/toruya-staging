"use strict";
import React from "react";
import StripeCheckout from 'react-stripe-checkout';
import "../shared/processing_bar.js";

UI.define("PlanCharge", function() {
  return class PlanCharge extends React.Component {
    static defaultProps = {
      chargeImmediately: true
    };

    state = {
      processing: false
    };

    toggleProcessing = () => {
      this.setState(prevState => ({ processing: !prevState.processing }));
    }

    onCharge = async (token) => {
      try {
        this.toggleProcessing();

        let data = {
          authenticity_token: this.props.formAuthenticityToken,
          plan: this.props.plan.level,
          upgrade_immediately: this.props.chargeImmediately
        };

        // event doesn't have id property.
        if (token.id) {
          data["token"] = token.id;
        }

        const response = await fetch(this.props.paymentPath, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          credentials: "same-origin",
          body: JSON.stringify(data),
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
      if (this.props.chargeImmediately) {
        return (
          <StripeCheckout
            token={this.onCharge}
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
              Pay this plan immediately
            </button>
          </StripeCheckout>
        )
      }

      return (
        <div className="btn btn-orange" onClick={this.onCharge}>
          <UI.ProcessingBar processing={this.state.processing} processingMessage={this.props.processingMessage} />
          Charge in next turn
        </div>
      )
    }
  };
});

export default UI.PlanCharge;
