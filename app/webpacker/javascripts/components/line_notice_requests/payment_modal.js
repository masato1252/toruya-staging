"use strict";

import React, { useState, useEffect } from "react";
import { loadStripe } from '@stripe/stripe-js';

import StripeCheckoutForm from "shared/stripe_checkout_form";
import ProcessingBar from "shared/processing_bar";
import ChargeFailedModal from "components/management/plans/charge_failed";

const PaymentModal = ({ props }) => {
  const [processing, setProcessing] = useState(false);

  useEffect(() => {
    const handleOpen = () => {
      $('#line-notice-checkout-modal').modal('show');
    };
    window.addEventListener('openLineNoticePaymentModal', handleOpen);
    return () => {
      window.removeEventListener('openLineNoticePaymentModal', handleOpen);
    };
  }, []);

  const showError = (message) => {
    setProcessing(false);
    $("#charge-failed-modal").data('error-message', message).modal("show");
  };

  const handle3DSAuthentication = async (errorData, paymentMethodId) => {
    try {
      const stripe = await loadStripe(props.stripeKey);
      const isSetupIntent = !!(errorData.setup_intent_id) ||
        (errorData.client_secret && errorData.client_secret.startsWith('seti_'));

      let result;
      if (isSetupIntent) {
        result = await stripe.confirmCardSetup(errorData.client_secret, {
          payment_method: paymentMethodId
        });

        if (result.error) {
          showError(errorData.message || result.error.message || "3DS認証に失敗しました。");
          return;
        }

        if (result.setupIntent && result.setupIntent.status === 'succeeded') {
          await retryPaymentAfter3DS(paymentMethodId, result.setupIntent.id, null);
        }
      } else {
        result = await stripe.confirmCardPayment(errorData.client_secret);

        if (result.error) {
          showError(errorData.message || result.error.message || "3DS認証に失敗しました。");
          return;
        }

        if (result.paymentIntent && result.paymentIntent.status === 'succeeded') {
          await retryPaymentAfter3DS(paymentMethodId, null, result.paymentIntent.id);
        }
      }
    } catch (error) {
      showError(errorData.message || "3DS認証中にエラーが発生しました。");
    }
  };

  const retryPaymentAfter3DS = async (paymentMethodId, setupIntentId, paymentIntentId) => {
    try {
      const retryPayload = { payment_method_id: paymentMethodId };
      if (setupIntentId) retryPayload.setup_intent_id = setupIntentId;
      if (paymentIntentId) retryPayload.payment_intent_id = paymentIntentId;

      const response = await fetch(props.approveUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        },
        body: JSON.stringify(retryPayload),
      });

      const data = await response.json();

      if (response.ok && data.status === 'success') {
        window.location.href = data.redirect_url;
      } else if (data.client_secret) {
        await handle3DSAuthentication(data, paymentMethodId);
      } else {
        showError(data.message || data.error || "決済に失敗しました。");
      }
    } catch (error) {
      showError("決済の再試行中にエラーが発生しました。");
    }
  };

  const handleToken = async (paymentMethodId) => {
    setProcessing(true);

    try {
      const response = await fetch(props.approveUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        },
        body: JSON.stringify({ payment_method_id: paymentMethodId }),
      });

      const data = await response.json();

      if (response.ok && data.status === 'success') {
        window.location.href = data.redirect_url;
      } else if (data.client_secret) {
        await handle3DSAuthentication(data, paymentMethodId);
      } else {
        showError(data.message || data.error || "決済に失敗しました。");
      }
    } catch (err) {
      showError("決済処理中にエラーが発生しました。");
    }
  };

  const handleFailure = (error) => {
    showError(error.message || "カード情報の入力に問題があります。");
  };

  return (
    <>
      <div className="modal fade" id="line-notice-checkout-modal" tabIndex="-1" role="dialog">
        <ProcessingBar processing={processing} />
        <div className="modal-content">
          <StripeCheckoutForm
            stripe_key={props.stripeKey}
            handleToken={handleToken}
            handleFailure={handleFailure}
            header="Toruya"
            desc=""
            details_desc={`今回のお支払い金額: ¥${props.chargeAmount}`}
            pay_btn="お支払い"
          />
        </div>
      </div>
      <ChargeFailedModal {...props} />
    </>
  );
};

export default PaymentModal;
