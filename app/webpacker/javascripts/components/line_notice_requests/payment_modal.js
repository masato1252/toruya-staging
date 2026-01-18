"use strict";

import React, { useState, useEffect } from "react";
import { CardElement, useStripe, useElements } from '@stripe/react-stripe-js';
import { loadStripe } from '@stripe/stripe-js';
import { Elements } from '@stripe/react-stripe-js';

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

const PaymentForm = ({ chargeAmount, approveUrl, i18n, onClose }) => {
  const [processing, setProcessing] = useState(false);
  const [errorMessage, setErrorMessage] = useState(null);
  const stripe = useStripe();
  const elements = useElements();

  const handleSubmit = async (event) => {
    event.preventDefault();
    setProcessing(true);
    setErrorMessage(null);

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
      setErrorMessage(error.message || "カード情報の入力に問題があります。");
      return;
    }

    // バックエンドに決済情報を送信
    try {
      const response = await fetch(approveUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        },
        body: JSON.stringify({
          payment_method_id: paymentMethod.id
        }),
      });

      const data = await response.json();

      if (response.ok && data.status === 'success') {
        // 成功 - リダイレクト
        window.location.href = data.redirect_url;
      } else {
        setProcessing(false);
        setErrorMessage(data.error || "決済に失敗しました。");
      }
    } catch (err) {
      setProcessing(false);
      setErrorMessage("決済処理中にエラーが発生しました。");
      console.error(err);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="mb-4">
        <label className="form-label">
          <strong>{i18n.chargeAmountLabel}</strong>
        </label>
        <div className="alert alert-info">
          <h4>{chargeAmount}円</h4>
        </div>
      </div>

      <div className="mb-4">
        <label className="form-label">
          <strong>{i18n.cardNumberLabel}</strong>
        </label>
        <div className="form-control" style={{ padding: '10px' }}>
          <CardElement options={CARD_ELEMENT_OPTIONS} />
        </div>
      </div>

      {errorMessage && (
        <div className="alert alert-danger">
          {errorMessage}
        </div>
      )}

      <div className="text-right">
        <button 
          type="button" 
          className="btn btn-default mr-2" 
          onClick={onClose}
          disabled={processing}
        >
          {i18n.cancelButton}
        </button>
        <button 
          type="submit" 
          className="btn btn-success" 
          disabled={!stripe || processing}
        >
          {processing ? i18n.processing : i18n.submitButton}
        </button>
      </div>
    </form>
  );
};

const PaymentModal = ({ props }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [stripePromise, setStripePromise] = useState(null);

  useEffect(() => {
    if (props.stripeKey) {
      setStripePromise(loadStripe(props.stripeKey));
    }
  }, [props.stripeKey]);

  useEffect(() => {
    const handleOpen = () => setIsOpen(true);
    window.addEventListener('openLineNoticePaymentModal', handleOpen);
    return () => window.removeEventListener('openLineNoticePaymentModal', handleOpen);
  }, []);

  if (!isOpen || !stripePromise) return null;

  return (
    <div className="modal fade in" style={{ display: 'block', backgroundColor: 'rgba(0,0,0,0.5)' }}>
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <button 
              type="button" 
              className="close" 
              onClick={() => setIsOpen(false)}
            >
              <span>&times;</span>
            </button>
            <h4 className="modal-title">{props.i18n.modalTitle}</h4>
          </div>
          <div className="modal-body">
            <Elements stripe={stripePromise}>
              <PaymentForm
                chargeAmount={props.chargeAmount}
                approveUrl={props.approveUrl}
                i18n={props.i18n}
                onClose={() => setIsOpen(false)}
              />
            </Elements>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PaymentModal;

