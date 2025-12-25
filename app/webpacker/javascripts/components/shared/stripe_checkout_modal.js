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
        if (error.response?.data?.client_secret) {
          // Handle 3DS authentication case
          const stripe = await loadStripe(props.stripe_key);
          const { error: confirmError, paymentIntent } = await stripe.confirmCardPayment(error.response.data.client_secret);

          setProcessing(true)

          if (confirmError) {
            setProcessing(false)
            const errorMessage = getStripeErrorMessage(confirmError);
            $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
          }
          else if (paymentIntent.status === 'succeeded') {
            // Payment successful, retry API call
            const [retryError, retryResponse] = await PaymentServices.payPlan({
              token: paymentMethodId,
              plan: plan_key,
              rank,
              business_owner_id: props.business_owner_id,
              payment_intent_id: paymentIntent.id
            });

            if (retryError) {
              setProcessing(false)
              // エラーレスポンスからメッセージを取得
              let errorMessage = "決済に失敗しました。もう一度お試しください。";
              if (retryError.response?.data?.stripe_error_code) {
                // Stripeエラーコードからメッセージを取得
                const stripeError = {
                  code: retryError.response.data.stripe_error_code,
                  message: retryError.response.data.stripe_error_message
                };
                errorMessage = getStripeErrorMessage(stripeError);
              } else if (retryError.response?.data?.message) {
                errorMessage = retryError.response.data.message;
              } else if (retryError.message) {
                errorMessage = retryError.message;
              }
              $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
            } else {
              window.location = retryResponse.data["redirect_path"];
            }
          }
          else if (paymentIntent.status === 'processing') {
            // Start polling payment status
            pollPaymentStatus(paymentIntent.id, paymentMethodId);
          }
        } else {
          setProcessing(false)
          // エラーレスポンスからメッセージを取得
          let errorMessage = "決済に失敗しました。もう一度お試しください。";
          if (error.response?.data?.stripe_error_code) {
            // Stripeエラーコードからメッセージを取得
            const stripeError = {
              code: error.response.data.stripe_error_code,
              message: error.response.data.stripe_error_message
            };
            errorMessage = getStripeErrorMessage(stripeError);
          } else if (error.response?.data?.message) {
            errorMessage = error.response.data.message;
          } else if (error.message) {
            errorMessage = error.message;
          }
          $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
        }
      } else {
        window.location = response.data["redirect_path"];
      }
    } catch (err) {
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
              // エラーレスポンスからメッセージを取得
              let errorMessage = "決済に失敗しました。もう一度お試しください。";
              if (retryError.response?.data?.stripe_error_code) {
                // Stripeエラーコードからメッセージを取得
                const stripeError = {
                  code: retryError.response.data.stripe_error_code,
                  message: retryError.response.data.stripe_error_message
                };
                errorMessage = getStripeErrorMessage(stripeError);
              } else if (retryError.response?.data?.message) {
                errorMessage = retryError.response.data.message;
              } else if (retryError.message) {
                errorMessage = retryError.message;
              }
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
