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

  
  stripePromise = null;
  currentStripeKey = null;

  componentDidMount() {
    this.initializeStripe();
  }

  componentDidUpdate(prevProps) {
    const currentStripeKey = this.props.stripeKey || this.props.stripe_key;
    if (currentStripeKey !== this.currentStripeKey) {
      this.initializeStripe();
    }
  }

  initializeStripe = () => {
    const stripeKey = this.props.stripeKey || this.props.stripe_key;
    if (stripeKey) {
      this.currentStripeKey = stripeKey;
      this.stripePromise = loadStripe(stripeKey);
    }
  }

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

  onDowngrade = async () => {
    try {
      this.toggleProcessing();

      // paymentPathからdowngradePathを推測
      // 例: /settings/payments -> /settings/payments/downgrade
      // 例: /lines/user_bot/owner/82/settings/payments -> /lines/user_bot/owner/82/settings/payments/downgrade
      const paymentPath = this.props.paymentPath || this.props.props?.paymentPath;
      const downgradePath = this.props.downgradePath || 
        (paymentPath ? paymentPath.replace(/\/?$/, '/downgrade') : '/settings/payments/downgrade');

      // social_service_user_idを取得
      const getSocialServiceUserId = () => {
        const urlParams = new URLSearchParams(window.location.search);
        const socialServiceUserId = urlParams.get('social_service_user_id');
        if (socialServiceUserId) {
          return socialServiceUserId;
        }
        const pathMatch = window.location.pathname.match(/social_service_user_id\/([^\/\?]+)/);
        if (pathMatch) {
          return pathMatch[1];
        }
        return null;
      };

      const socialServiceUserId = getSocialServiceUserId();
      
      // 選択されたプラン情報を取得
      const planKey = this.props.plan?.key || this.props.plan?.level;
      const rank = this.props.rank || 0;
      
      // パラメータを構築
      const params = new URLSearchParams();
      if (planKey) {
        params.append('plan', planKey);
      }
      if (rank) {
        params.append('rank', rank);
      }
      if (socialServiceUserId) {
        params.append('social_service_user_id', socialServiceUserId);
      }
      
      const url = `${downgradePath}?${params.toString()}`;

      // ダウングレードはGETリクエストで、リダイレクトが返されるため、直接window.locationを使用
      window.location.href = url;
    } catch (err) {
      this.toggleProcessing();
      console.error("Downgrade error:", err);
      // ダウングレード失敗時はエラーモーダルではなく、通常のエラーメッセージを表示
      alert(this.props.i18n?.downgradeFailed || "ダウングレードに失敗しました。ページを再読み込みしてください。");
    }
  };

  render() {
    if (this.props.chargeImmediately) {
      if (!this.stripePromise) {
        return null; // Stripe is loading
      }

      return (
        <>
          <Elements stripe={this.stripePromise}>
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
        <div className="btn btn-orange" onClick={this.onDowngrade}>
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
