"use strict";

import React, { useState, useEffect } from "react";
import { CardElement, useStripe, useElements } from '@stripe/react-stripe-js';
import { loadStripe } from '@stripe/stripe-js';
import { Elements } from '@stripe/react-stripe-js';

const CARD_ELEMENT_OPTIONS = {
  hidePostalCode: true,
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

  const handle3DSAuthentication = async (errorData, paymentMethodId) => {
    console.log('Starting 3DS authentication:', errorData);
    
    try {
      // PaymentIntent か SetupIntent かを判定
      const isSetupIntent = !!(errorData.setup_intent_id) || (errorData.client_secret && errorData.client_secret.startsWith('seti_'));
      
      console.log('Intent type detection:', {
        setup_intent_id: errorData.setup_intent_id,
        payment_intent_id: errorData.payment_intent_id,
        client_secret_prefix: errorData.client_secret ? errorData.client_secret.substring(0, 5) : null,
        isSetupIntent: isSetupIntent
      });
      
      let result;
      if (isSetupIntent) {
        // SetupIntent の 3DS認証
        result = await stripe.confirmCardSetup(errorData.client_secret, {
          payment_method: paymentMethodId
        });
        
        console.log('SetupIntent confirmation result:', result);
        
        if (result.error) {
          setProcessing(false);
          setErrorMessage(errorData.message || result.error.message || "3DS認証に失敗しました。");
          return;
        }
        
        if (result.setupIntent && result.setupIntent.status === 'succeeded') {
          console.log('SetupIntent 3DS succeeded, retrying...');
          await retryPaymentAfter3DS(paymentMethodId, result.setupIntent.id, null);
        }
      } else {
        // PaymentIntent の 3DS認証
        result = await stripe.confirmCardPayment(errorData.client_secret);
        
        console.log('PaymentIntent confirmation result:', result);
        
        if (result.error) {
          setProcessing(false);
          setErrorMessage(errorData.message || result.error.message || "3DS認証に失敗しました。");
          return;
        }
        
        if (result.paymentIntent && result.paymentIntent.status === 'succeeded') {
          console.log('PaymentIntent 3DS succeeded, retrying...');
          await retryPaymentAfter3DS(paymentMethodId, null, result.paymentIntent.id);
        }
      }
    } catch (error) {
      console.error('3DS authentication error:', error);
      setProcessing(false);
      setErrorMessage(errorData.message || "3DS認証中にエラーが発生しました。");
    }
  };

  const retryPaymentAfter3DS = async (paymentMethodId, setupIntentId, paymentIntentId) => {
    console.log('Retrying payment after 3DS:', { setupIntentId, paymentIntentId });
    
    try {
      const retryPayload = {
        payment_method_id: paymentMethodId
      };
      
      if (setupIntentId) {
        retryPayload.setup_intent_id = setupIntentId;
      }
      if (paymentIntentId) {
        retryPayload.payment_intent_id = paymentIntentId;
      }
      
      const response = await fetch(approveUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        },
        body: JSON.stringify(retryPayload),
      });

      const data = await response.json();
      console.log('Retry response:', data);

      if (response.ok && data.status === 'success') {
        // 成功 - リダイレクト
        window.location.href = data.redirect_url;
      } else if (data.client_secret) {
        // 再度3DS認証が必要（PaymentIntentの3DS）
        console.log('Second 3DS authentication required');
        await handle3DSAuthentication(data, paymentMethodId);
      } else {
        setProcessing(false);
        setErrorMessage(data.message || data.error || "決済に失敗しました。");
      }
    } catch (error) {
      console.error('Retry payment error:', error);
      setProcessing(false);
      setErrorMessage("決済の再試行中にエラーが発生しました。");
    }
  };

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
      console.log('Backend response:', data);

      if (response.ok && data.status === 'success') {
        // 成功 - リダイレクト
        window.location.href = data.redirect_url;
      } else if (data.client_secret) {
        // 3DS認証が必要な場合
        console.log('3DS authentication required');
        await handle3DSAuthentication(data, paymentMethod.id);
      } else {
        setProcessing(false);
        // バックエンドから返された親切なメッセージを優先的に表示
        setErrorMessage(data.message || data.error || "決済に失敗しました。");
      }
    } catch (err) {
      setProcessing(false);
      setErrorMessage("決済処理中にエラーが発生しました。");
      console.error(err);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="mb-4" style={{ display: 'flex', alignItems: 'center', fontSize: '16px', marginBottom: '20px' }}>
        <strong style={{ marginRight: '8px' }}>{i18n.chargeAmountLabel}:</strong>
        <span>{chargeAmount}円</span>
      </div>

      <div className="mb-4">
        <CardElement options={CARD_ELEMENT_OPTIONS} />
      </div>

      {errorMessage && (
        <div className="alert alert-danger" style={{ marginTop: '20px' }}>
          {errorMessage}
        </div>
      )}

      <div className="text-right">
        <button 
          type="button" 
          className="btn btn-tarco mr-2" 
          onClick={onClose}
          disabled={processing}
        >
          {i18n.cancelButton}
        </button>
        <button 
          type="submit" 
          className="btn btn-yellow" 
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
    console.log('[PaymentModal] Reactコンポーネント初期化');
    console.log('[PaymentModal] props.stripeKey:', props.stripeKey ? '設定あり' : '設定なし');
    if (props.stripeKey) {
      console.log('[PaymentModal] Stripe初期化開始');
      setStripePromise(loadStripe(props.stripeKey));
    } else {
      console.error('[PaymentModal] エラー: stripeKeyが設定されていません');
    }
  }, [props.stripeKey]);

  useEffect(() => {
    console.log('[PaymentModal] イベントリスナー設定');
    const handleOpen = () => {
      console.log('[PaymentModal] openLineNoticePaymentModal イベント受信 - モーダル表示');
      setIsOpen(true);
    };
    window.addEventListener('openLineNoticePaymentModal', handleOpen);
    console.log('[PaymentModal] イベントリスナー設定完了');
    return () => {
      console.log('[PaymentModal] イベントリスナー解除');
      window.removeEventListener('openLineNoticePaymentModal', handleOpen);
    };
  }, []);

  console.log('[PaymentModal] レンダリング状態:', { isOpen, stripePromise: !!stripePromise });
  
  if (!isOpen) {
    console.log('[PaymentModal] モーダル非表示（isOpen=false）');
    return null;
  }
  
  if (!stripePromise) {
    console.log('[PaymentModal] モーダル非表示（stripePromise=null）');
    return null;
  }
  
  console.log('[PaymentModal] モーダル表示中');

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

