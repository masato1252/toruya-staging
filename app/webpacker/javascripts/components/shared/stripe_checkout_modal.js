import React, { useState } from "react";
import { loadStripe } from "@stripe/stripe-js";

import StripeCheckoutForm from "shared/stripe_checkout_form"
import { PaymentServices } from "components/user_bot/api"
import ProcessingBar from "shared/processing_bar";
import ChargeFailedModal from "components/management/plans/charge_failed";

const StripeCheckoutModal = ({plan_key, rank, props, ...rest}) => {
  const [processing, setProcessing] = useState(false)

  // Stripeエラーコードを日本語メッセージに変換
  const getStripeErrorMessage = (error) => {
    if (!error) return "決済に失敗しました。もう一度お試しください。";
    
    // Stripeエラーコードからメッセージを取得
    const errorCode = error.code || error.type;
    const errorMessage = error.message || "";
    
    switch (errorCode) {
      case 'card_declined':
        return "カード決済が拒否されました。カード会社にお問い合わせください。";
      case 'expired_card':
        return "カードの有効期限が切れています。別のカードをお試しください。";
      case 'incorrect_cvc':
        return "セキュリティーコード（CVC）が正しくありません。もう一度ご確認ください。";
      case 'incorrect_number':
        return "カード番号が正しくありません。もう一度ご確認ください。";
      case 'processing_error':
        return "処理中にエラーが発生しました。しばらく時間をおいてから再度お試しください。";
      case 'insufficient_funds':
        return "カードの残高が不足しています。別のカードをお試しください。";
      case 'generic_decline':
        return "カード決済が拒否されました。カード会社にお問い合わせください。";
      case 'lost_card':
        return "このカードは紛失カードとして報告されています。カード会社にお問い合わせください。";
      case 'stolen_card':
        return "このカードは盗難カードとして報告されています。カード会社にお問い合わせください。";
      default:
        // エラーメッセージがあればそれを使用、なければデフォルトメッセージ
        return errorMessage || "決済に失敗しました。もう一度お試しください。";
    }
  }

  const handleToken = async (paymentMethodId) => {
    setProcessing(true)

    try {
      const [error, response] = await PaymentServices.payPlan({
        token: paymentMethodId,
        plan: plan_key,
        rank,
        business_owner_id: props.business_owner_id
      })
      setProcessing(false)

      if (error) {
        console.log('=== Payment error received ===');
        console.log('Error response:', error.response?.data);
        
        if (error.response?.data?.client_secret) {
          console.log('Client secret found, starting 3DS flow');
          // Handle 3DS authentication case
          const stripe = await loadStripe(props.stripe_key);
          const errorData = error.response.data;
          
          // SetupIntent か PaymentIntent かを判定
          const isSetupIntent = !!(errorData.setup_intent_id) || (errorData.client_secret && errorData.client_secret.startsWith('seti_'));
          console.log('Is SetupIntent?', isSetupIntent);
          console.log('Client secret prefix:', errorData.client_secret?.substring(0, 5));
          
          let confirmError, intent;
          
          if (isSetupIntent) {
            console.log('Calling stripe.confirmCardSetup...');
            // SetupIntent の場合
            const result = await stripe.confirmCardSetup(errorData.client_secret, {
              payment_method: paymentMethodId
            });
            console.log('confirmCardSetup result:', result);
            confirmError = result.error;
            intent = result.setupIntent;
          } else {
            console.log('Calling stripe.confirmCardPayment...');
            // PaymentIntent の場合
            const result = await stripe.confirmCardPayment(errorData.client_secret);
            console.log('confirmCardPayment result:', result);
            confirmError = result.error;
            intent = result.paymentIntent;
          }

          console.log('confirmError:', confirmError);
          console.log('intent:', intent);
          console.log('intent status:', intent?.status);

          setProcessing(true)

          if (confirmError) {
            console.log('Confirm error detected:', confirmError);
            setProcessing(false)
            // バックエンドから返されたメッセージを優先的に表示
            const errorMessage = errorData.message || getStripeErrorMessage(confirmError);
            $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
          }
          else if (intent && intent.status === 'succeeded') {
            console.log('3DS authentication succeeded, retrying payment...');
            // Payment/Setup successful, retry API call
            const retryData = {
              token: paymentMethodId,
              plan: plan_key,
              rank,
              business_owner_id: props.business_owner_id
            };
            
            // SetupIntentとPaymentIntentで送るパラメータを分ける
            if (isSetupIntent) {
              retryData.setup_intent_id = intent.id;
              console.log('Adding setup_intent_id to retry:', intent.id);
            } else {
              retryData.payment_intent_id = intent.id;
              console.log('Adding payment_intent_id to retry:', intent.id);
            }
            
            console.log('Retry request data:', retryData);
            
            const [retryError, retryResponse] = await PaymentServices.payPlan(retryData);

            console.log('Retry response - error:', retryError);
            console.log('Retry response - success:', retryResponse);

            if (retryError) {
              console.log('Retry error response data:', retryError.response?.data);
              
              // リトライ後も3DS認証が必要な場合（PaymentIntentの3DS認証）
              if (retryError.response?.data?.client_secret) {
                console.log('Retry also requires 3DS authentication (PaymentIntent)');
                const retryErrorData = retryError.response.data;
                
                // PaymentIntent の 3DS認証
                const { error: paymentConfirmError, paymentIntent } = await stripe.confirmCardPayment(
                  retryErrorData.client_secret
                );
                
                console.log('Payment confirmCardPayment result:', { error: paymentConfirmError, paymentIntent });
                
                if (paymentConfirmError) {
                  setProcessing(false);
                  const errorMessage = retryErrorData.message || getStripeErrorMessage(paymentConfirmError);
                  console.log('Payment confirmation error:', errorMessage);
                  $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
                } else if (paymentIntent && paymentIntent.status === 'succeeded') {
                  console.log('Payment 3DS succeeded, final retry...');
                  // PaymentIntent の 3DS認証成功、最終リトライ
                  const [finalError, finalResponse] = await PaymentServices.payPlan({
              token: paymentMethodId,
              plan: plan_key,
              rank,
              business_owner_id: props.business_owner_id,
              payment_intent_id: paymentIntent.id
            });

                  if (finalError) {
                    setProcessing(false);
                    const errorMessage = finalError.response?.data?.message || "決済に失敗しました。もう一度お試しください。";
                    console.log('Final retry error:', errorMessage);
                    $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
                  } else {
                    console.log('Payment successful, redirecting...');
                    window.location = finalResponse.data["redirect_path"];
                  }
                } else if (paymentIntent && paymentIntent.status === 'processing') {
                  console.log('Payment processing, start polling...');
                  pollPaymentStatus(paymentIntent.id, paymentMethodId);
                }
              } else {
              setProcessing(false)
                // バックエンドから返されたメッセージを優先的に表示
                let errorMessage = retryError.response?.data?.message || "決済に失敗しました。もう一度お試しください。";
                console.log('Showing error message:', errorMessage);
              $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
              }
            } else {
              console.log('Retry succeeded, redirecting to:', retryResponse.data["redirect_path"]);
              window.location = retryResponse.data["redirect_path"];
            }
          }
          else if (intent && intent.status === 'processing') {
            // Start polling payment status (PaymentIntentのみ、SetupIntentにはprocessingステータスはない)
            pollPaymentStatus(intent.id, paymentMethodId);
          }
        } else {
          console.log('No client_secret, showing error message');
          setProcessing(false)
          // バックエンドから返されたメッセージを優先的に表示
          const errorMessage = error.response?.data?.message || "決済に失敗しました。もう一度お試しください。";
          console.log('Error message:', errorMessage);
          $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
        }
      } else {
        console.log('Payment successful, redirecting...');
        window.location = response.data["redirect_path"];
      }
    } catch (err) {
      console.error('=== Catch block reached ===');
      console.error('Error:', err);
      setProcessing(false);
      const errorMessage = err.message || "決済処理中にエラーが発生しました。もう一度お試しください。";
      $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
    }
  }

  const pollPaymentStatus = async (paymentIntentId, paymentMethodId) => {
    try {
      const response = await fetch(`/stripe_payment_status?payment_intent_id=${paymentIntentId}`, {
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
            setProcessing(false);
            const [retryError, retryResponse] = await PaymentServices.payPlan({
              token: paymentMethodId,
              plan: plan_key,
              rank,
              business_owner_id: props.business_owner_id,
              payment_intent_id: paymentIntentId
            });

            if (retryError) {
              // バックエンドから返されたメッセージを優先的に表示
              const errorMessage = retryError.response?.data?.message || "決済に失敗しました。もう一度お試しください。";
              $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
            } else {
              window.location = retryResponse.data["redirect_path"];
            }

            break;
          case 'failed':
            setProcessing(false);
            // PaymentIntentのlast_payment_errorからエラー情報を取得
            let failedErrorMessage = "決済に失敗しました。もう一度お試しください。";
            if (result.last_payment_error) {
              const stripeError = {
                code: result.last_payment_error.code,
                message: result.last_payment_error.message
              };
              failedErrorMessage = getStripeErrorMessage(stripeError);
            } else if (result.error_message) {
              failedErrorMessage = result.error_message;
            }
            $("#charge-failed-modal").data('error-message', failedErrorMessage).modal("show");
            break;
          case 'processing':
            // Continue polling
            setTimeout(() => pollPaymentStatus(paymentIntentId, paymentMethodId), 2000);
            break;
          case 'requires_action':
            // Handle cases that require additional actions
            const stripe = await loadStripe(props.stripe_key);
            const { error, paymentIntent } = await stripe.handleCardAction(result.client_secret);

            if (error) {
              setProcessing(false);
              const errorMessage = getStripeErrorMessage(error);
              $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
            } else if (paymentIntent.status === 'succeeded') {
              setProcessing(false);
              window.location = result.redirect_path;
            } else {
              // Continue polling
              setTimeout(() => pollPaymentStatus(paymentIntentId, paymentMethodId), 2000);
            }
            break;
        }
      } else {
        setProcessing(false);
        const errorMessage = "決済処理中にエラーが発生しました。もう一度お試しください。";
        $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
      }
    } catch (err) {
      setProcessing(false);
      const errorMessage = err.message || "決済処理中にエラーが発生しました。もう一度お試しください。";
      $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
    }
  };

  const handleFailed = (error) => {
    console.log(error.message);
  }

  return (
    <>
      <div className="modal fade" id="checkout-modal" tabIndex="-1" role="dialog">
        <ProcessingBar processing={processing} />
        <div className="modal-content">
          <StripeCheckoutForm
            handleToken={handleToken}
            handleFailure={handleFailed}
            {...rest}
          />
        </div>
      </div>
      <ChargeFailedModal {...props} />
    </>
  )
}

export default StripeCheckoutModal
