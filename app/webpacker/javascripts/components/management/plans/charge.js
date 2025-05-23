"use strict";
import React, { useState } from "react";
import { CardElement, useStripe, useElements } from '@stripe/react-stripe-js';
import { loadStripe } from '@stripe/stripe-js';
import { Elements } from '@stripe/react-stripe-js';
import ProcessingBar from "shared/processing_bar";
import ChargeFailedModal from "./charge_failed";

const CARD_ELEMENT_OPTIONS = {
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

const PaymentForm = ({ onSuccess, stripeKey, plan, i18n }) => {
  const [processing, setProcessing] = useState(false);
  const stripe = useStripe();
  const elements = useElements();

  const handleSubmit = async (event) => {
    event.preventDefault();
    setProcessing(true);

    if (!stripe || !elements) {
      return;
    }

    const card = elements.getElement(CardElement);
    const { error, paymentMethod } = await stripe.createPaymentMethod({
      type: 'card',
      card: card,
    });

    if (error) {
      setProcessing(false);
      console.error(error);
    } else {
      onSuccess(paymentMethod.id);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <ProcessingBar processing={processing} />
      <CardElement options={CARD_ELEMENT_OPTIONS} />
      <button type="submit" disabled={!stripe || processing} className="btn btn-yellow">
        {i18n.saveAndPay || i18n.save_and_pay}
      </button>
    </form>
  );
};

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

  onCharge = async (paymentMethodId) => {
    try {
      this.toggleProcessing();

      let data = {
        authenticity_token: this.props.formAuthenticityToken,
        plan: this.props.plan.key,
        rank: this.props.rank,
        change_immediately: this.props.chargeImmediately,
        business_owner_id: this.props.business_owner_id,
        token: paymentMethodId
      };

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
        if (err.client_secret) {
          // Handle cases that require user action
          const stripe = await loadStripe(this.props.stripeKey || this.props.stripe_key);
          let result;

          switch (err.plan) {
            case 'requires_payment_method':
            case 'requires_source':
              result = await stripe.confirmCardPayment(err.client_secret, {
                payment_method: paymentMethodId
              });
              break;
            case 'requires_action':
              result = await stripe.handleCardAction(err.client_secret);
              break;
            case 'requires_confirmation':
              result = await stripe.confirmCardPayment(err.client_secret);
              break;
            default:
              throw err;
          }

          if (result.error) {
            throw result.error;
          } else if (result.paymentIntent && result.paymentIntent.status === 'succeeded') {
            // Payment successful, retry backend API call
            const retryResponse = await fetch(this.props.paymentPath, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                "X-Requested-With": "XMLHttpRequest",
              },
              credentials: "same-origin",
              body: JSON.stringify({
                ...data,
                payment_intent_id: result.paymentIntent.id
              }),
            });

            if (retryResponse.ok) {
              const result = await retryResponse.json();
              this.toggleProcessing();
              window.location = result["redirect_path"];
            } else {
              throw Error("Payment failed after confirmation");
            }
          } else if (result.paymentIntent && result.paymentIntent.status === 'processing') {
            // Start polling payment status
            this.pollPaymentStatus(result.paymentIntent.id);
          }
        } else {
          throw err;
        }
      } else {
        throw Error("Payment failed");
      }
    }
    catch (err) {
      this.toggleProcessing()
      $("#charge-failed-modal").modal("show");
    }
  };

  pollPaymentStatus = async (paymentIntentId) => {
    try {
      const response = await fetch(`/stripe_payment_status?payment_intent_id=${paymentIntentId}&type=subscription`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          "X-Requested-With": "XMLHttpRequest",
        },
        credentials: "same-origin"
      });

      if (response.ok) {
        const result = await response.json();

        switch (result.status) {
          case 'succeeded':
            this.toggleProcessing();
            window.location = result.redirect_path;
            break;
          case 'failed':
            throw Error(result.error || "Payment failed");
          case 'processing':
            // Continue polling
            setTimeout(() => this.pollPaymentStatus(paymentIntentId), 2000);
            break;
          case 'requires_action':
            // Handle cases that require additional actions
            const stripe = await loadStripe(this.props.stripeKey || this.props.stripe_key);
            const { error, paymentIntent } = await stripe.handleCardAction(result.client_secret);

            if (error) {
              throw error;
            } else if (paymentIntent.status === 'succeeded') {
              this.toggleProcessing();
              window.location = result.redirect_path;
            } else {
              // Continue polling
              setTimeout(() => this.pollPaymentStatus(paymentIntentId), 2000);
            }
            break;
        }
      } else {
        throw Error("Failed to check payment status");
      }
    } catch (err) {
      this.toggleProcessing();
      $("#charge-failed-modal").modal("show");
    }
  };

  render() {
    if (this.props.chargeImmediately) {
      const stripePromise = loadStripe(this.props.stripeKey || this.props.stripe_key);

      return (
        <>
          <Elements stripe={stripePromise}>
            <PaymentForm
              onSuccess={this.onCharge}
              stripeKey={this.props.stripeKey || this.props.stripe_key}
              plan={this.props.plan}
              i18n={this.props.i18n}
            />
          </Elements>
          <ChargeFailedModal {...this.props} />
        </>
      );
    }

    if (this.props.downgrade) {
      return (
        <div className="btn btn-orange" onClick={this.onCharge}>
          {this.props.i18n.downgradeConfirmBtn || this.props.i18n.downgrade.confirm_btn}
        </div>
      );
    }

    return (
      <div className="btn btn-yellow" onClick={this.onCharge}>
        {this.props.i18n.save}
      </div>
    );
  }
}

export default PlanCharge;
