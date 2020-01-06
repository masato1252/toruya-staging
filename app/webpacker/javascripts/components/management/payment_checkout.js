"use strict";
import React from "react";
import StripeCheckout from 'react-stripe-checkout';
import ProcessingBar from "shared/processing_bar";

class PaymentCheckout extends React.Component {
  state = {
    processing: false
  }

  toggleProcessing = () => {
    this.setState(prevState => ({ processing: !prevState.processing }));
  }

  onToken = (token) => {
    this.toggleProcessing()
    $("#stripe-token").val(token.id);
    $(`#${this.props.formlId}`).submit();
  };

  render() {
    return (
      <StripeCheckout
        token={this.onToken}
        stripeKey={this.props.stripeKey}
        amount={this.props.cost}
        currency="JPY"
        email={this.props.email}
        panelLabel="Pay"
        allowRememberMe={false}
        locale={this.props.locale}
        name="Toruya"
        description={this.props.description}
      >
        <ProcessingBar processing={this.state.processing} processingMessage={this.props.processingMessage} />
        <button className="btn btn-yellow" rel="nofollow">
          {this.props.i18n.payBtnText}
        </button>
      </StripeCheckout>
    )
  }
};

export default PaymentCheckout;
