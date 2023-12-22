"use strict";
import React from "react";
import StripeCheckout from 'react-stripe-checkout';
import ProcessingBar from "shared/processing_bar";
import ChargeFailedModal from "./charge_failed";

class PlanCharge extends React.Component {
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
        plan: this.props.plan.key,
        rank: this.props.rank,
        change_immediately: this.props.chargeImmediately,
        business_owner_id: this.props.business_owner_id
      };

      // event doesn't have id property.
      if (token.id) {
        data["token"] = token.id;
      }

      const response = await fetch(this.props.paymentPath, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          "X-Requested-With": "XMLHttpRequest",
        },
        credentials: "same-origin",
        body: JSON.stringify(data),
      })

      if (response.ok) {
        const result = await response.json()
        this.toggleProcessing()
        window.location = result["redirect_path"];
      } else if (response.status === 422) {
        const err = await response.json()
        throw err
      } else {
        throw Error("Payment failed");
      }
    }
    catch (err) {
      this.toggleProcessing()
      $("#charge-failed-modal").modal("show");
    }
  };

  render() {
    if (this.props.chargeImmediately) {
      return (
        <StripeCheckout
          token={this.onCharge}
          stripeKey={this.props.stripeKey || this.props.stripe_key}
          amount={this.props.plan?.costWithFee || this.props.plan.cost_with_fee}
          currency="JPY"
          email={this.props.email}
          panelLabel="Pay"
          allowRememberMe={false}
          locale={this.props.locale}
          name="Toruya"
          description={this.props.plan.name}
          >
          <ProcessingBar
            processing={this.state.processing}
            processingMessage={this.props.processingMessage} />
          <ChargeFailedModal
            {...this.props}
          />
          <div
            className={`btn btn-yellow`} rel="nofollow">
            {this.props.i18n.saveAndPay || this.props.i18n.save_and_pay}
          </div>
        </StripeCheckout>
      )
    }

    if (this.props.downgrade) {
      return (
        <div className="btn btn-orange" onClick={this.onCharge}>
          {this.props.i18n.downgradeConfirmBtn || this.props.i18n.downgrade.confirm_btn}
        </div>
      )
    }

    return (
      <div className="btn btn-yellow" onClick={this.onCharge}>
        {this.props.i18n.save}
      </div>
    )
  }
};

export default PlanCharge;
