"use strict";
import React, { useState } from "react";
import { CardElement, useStripe, useElements } from '@stripe/react-stripe-js';
import { loadStripe } from '@stripe/stripe-js';
import { Elements } from '@stripe/react-stripe-js';
import ProcessingBar from "shared/processing_bar";
import ChargeFailedModal from "./charge_failed";
import toastr from "toastr";

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

const PaymentForm = ({ onSuccess, stripeKey, plan, i18n, onError }) => {
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
      if (onError) {
        onError(error.message || "カード情報の入力に問題があります。");
      }
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
    processing: false,
    errorMessage: null
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
    console.log('=== onCharge called ===', paymentMethodId);
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

      console.log('Sending request to:', this.props.paymentPath);
      console.log('Request data:', data);

      const response = await fetch(this.props.paymentPath, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          "X-Requested-With": "XMLHttpRequest",
        },
        credentials: "same-origin",
        body: JSON.stringify(data),
      })

      console.log('Response status:', response.status);
      console.log('Response ok:', response.ok);

      if (response.ok) {
        const result = await response.json()
        this.toggleProcessing()
        window.location = result["redirect_path"];
      } else if (response.status === 422) {
        console.log('422 response received');
        const err = await response.json()
        console.log('Error response:', err);
        console.log('Has client_secret?', !!err.client_secret);
        
        if (err.client_secret) {
          console.log('Entering client_secret handling block');
          // Handle cases that require user action
          const stripe = await loadStripe(this.props.stripeKey || this.props.stripe_key);
          let result;
          
          // バックエンドから返されたユーザー向けメッセージを保持
          const backendMessage = err.message || "決済処理に失敗しました。";

          // SetupIntent か PaymentIntent かを判定（より厳密に）
          // SetupIntentのclient_secretは'seti_'で始まる
          // PaymentIntentのclient_secretは'pi_'で始まる
          const isSetupIntent = !!(err.setup_intent_id) || (err.client_secret && err.client_secret.startsWith('seti_'));
          
          // デバッグログ
          console.log('Payment intent detection:', {
            setup_intent_id: err.setup_intent_id,
            payment_intent_id: err.payment_intent_id,
            client_secret_prefix: err.client_secret ? err.client_secret.substring(0, 5) : null,
            isSetupIntent: isSetupIntent,
            error_type: err.error_type
          });
          
          if (isSetupIntent) {
            // SetupIntent の場合（カード登録時）
            try {
              result = await stripe.confirmCardSetup(err.client_secret, {
                payment_method: paymentMethodId
              });
            } catch (stripeError) {
              // Stripe APIエラーが発生した場合も、バックエンドのメッセージを使用
              console.error('Stripe confirmCardSetup error:', stripeError);
              throw new Error(backendMessage);
            }
            
            if (result.error) {
              // result.errorの場合も、バックエンドのメッセージを使用
              console.error('Stripe confirmCardSetup result error:', result.error);
              throw new Error(backendMessage);
            } else if (result.setupIntent && result.setupIntent.status === 'succeeded') {
              // Setup successful, retry backend API call
              const retryResponse = await fetch(this.props.paymentPath, {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  "X-Requested-With": "XMLHttpRequest",
                },
                credentials: "same-origin",
                body: JSON.stringify({
                  ...data,
                  setup_intent_id: result.setupIntent.id
                }),
              });

              if (retryResponse.ok) {
                const result = await retryResponse.json();
                this.toggleProcessing();
                window.location = result["redirect_path"];
              } else {
                let errorMessage = "カード登録の確認後に失敗しました。";
                try {
                  const errorData = await retryResponse.json();
                  // messageには既にユーザー向けメッセージとStripeエラーの両方が含まれている
                  errorMessage = errorData.message || errorMessage;
                } catch (e) {
                  // JSON解析に失敗した場合はデフォルトメッセージを使用
                }
                throw new Error(errorMessage);
              }
            }
          } else {
            // PaymentIntent の場合（決済時）
            const errorType = err.error_type || err.plan;
            
            console.log('PaymentIntent branch:', {
              errorType: errorType,
              client_secret_prefix: err.client_secret ? err.client_secret.substring(0, 5) : null
            });
            
            // client_secretがSetupIntentなのにこのブランチに来た場合はエラー
            if (err.client_secret && err.client_secret.startsWith('seti_')) {
              console.error('ERROR: SetupIntent client_secret in PaymentIntent branch!');
              throw new Error(backendMessage);
            }
            
            // サポートされていないエラータイプの場合は、バックエンドから受け取ったメッセージを使用
            if (!['requires_payment_method', 'requires_source', 'requires_action', 'requires_confirmation'].includes(errorType)) {
              throw new Error(backendMessage);
            }
            
            try {
              // client_secretのタイプを再確認（念のため）
              const clientSecretType = err.client_secret.startsWith('seti_') ? 'setup' : 
                                      err.client_secret.startsWith('pi_') ? 'payment' : 'unknown';
              
              console.log('Attempting Stripe call:', {
                errorType: errorType,
                clientSecretType: clientSecretType
              });
              
              switch (errorType) {
                case 'requires_payment_method':
                case 'requires_source':
                  // SetupIntentの場合は間違ったブランチに来ているのでエラー
                  if (clientSecretType === 'setup') {
                    console.error('ERROR: SetupIntent in PaymentIntent requires_payment_method case');
                    throw new Error(backendMessage);
                  }
                  result = await stripe.confirmCardPayment(err.client_secret, {
                    payment_method: paymentMethodId
                  });
                  break;
                case 'requires_action':
                  // handleCardActionはSetupIntentとPaymentIntentの両方で使える
                  result = await stripe.handleCardAction(err.client_secret);
                  break;
                case 'requires_confirmation':
                  // SetupIntentの場合は間違ったブランチに来ているのでエラー
                  if (clientSecretType === 'setup') {
                    console.error('ERROR: SetupIntent in PaymentIntent requires_confirmation case');
                    throw new Error(backendMessage);
                  }
                  result = await stripe.confirmCardPayment(err.client_secret);
                  break;
              }
            } catch (stripeError) {
              // Stripe APIエラーが発生した場合も、バックエンドのメッセージを使用
              console.error('Stripe API error:', stripeError);
              throw new Error(backendMessage);
            }

            if (result.error) {
              // result.errorの場合も、バックエンドのメッセージを使用
              console.error('Stripe confirmCardPayment result error:', result.error);
              throw new Error(backendMessage);
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
                // リトライ失敗時のエラーメッセージを取得
                let errorMessage = "決済の確認後に失敗しました。";
                try {
                  const errorData = await retryResponse.json();
                  // messageには既にユーザー向けメッセージとStripeエラーの両方が含まれている
                  errorMessage = errorData.message || errorMessage;
                } catch (e) {
                  // JSON解析に失敗した場合はデフォルトメッセージを使用
                }
                throw new Error(errorMessage);
              }
            } else if (result.paymentIntent && result.paymentIntent.status === 'processing') {
              // Start polling payment status
              this.pollPaymentStatus(result.paymentIntent.id);
            }
          }
        } else {
          // client_secretがない場合、詳細なエラーメッセージを表示
          // messageには既にユーザー向けメッセージとStripeエラーの両方が含まれている
          let errorMessage = err.message || "決済に失敗しました。";
          
          throw new Error(errorMessage);
        }
      } else {
        // エラーレスポンスからメッセージを取得
        let errorMessage = "決済に失敗しました。";
        try {
          const errorData = await response.json();
          // messageには既にユーザー向けメッセージとStripeエラーの両方が含まれている
          errorMessage = errorData.message || errorMessage;
        } catch (e) {
          // JSON解析に失敗した場合はデフォルトメッセージを使用
          errorMessage = `決済に失敗しました。ステータスコード: ${response.status}`;
        }
        throw new Error(errorMessage);
      }
    }
    catch (err) {
      console.log('=== Catch block reached ===');
      this.toggleProcessing()
      
      // バックエンドから返されたエラーメッセージをそのまま表示
      const errorMessage = err.message || (typeof err === 'string' ? err : "決済に失敗しました。もう一度お試しください。");
      
      // デバッグ用にコンソールに詳細を出力
      console.error('Payment error details:', err);
      console.error('Error message:', errorMessage);
      
      // エラーメッセージをstateに保存してモーダルに渡す
      this.setState({ errorMessage });
      $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
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
            const failedMessage = result.error || result.message || "決済に失敗しました。";
            throw new Error(failedMessage);
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
        // ステータス確認失敗時のエラーメッセージを取得
        let errorMessage = "決済状況の確認に失敗しました。";
        try {
          const errorData = await response.json();
          errorMessage = errorData.message || errorMessage;
        } catch (e) {
          // JSON解析に失敗した場合はデフォルトメッセージを使用
        }
        throw new Error(errorMessage);
      }
    } catch (err) {
      this.toggleProcessing();
      
      // バックエンドから返されたエラーメッセージをそのまま表示
      const errorMessage = err.message || "決済状況の確認に失敗しました。";
      
      // エラーメッセージをstateに保存してモーダルに渡す
      this.setState({ errorMessage });
      $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
    }
  };

  handleRestrictedClick = () => {
    toastr.warning("プラン変更は1日1回までとなります");
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
              onError={(errorMessage) => {
                this.setState({ errorMessage });
                $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
              }}
              stripeKey={this.props.stripeKey || this.props.stripe_key}
              plan={this.props.plan}
              i18n={this.props.i18n}
            />
          </Elements>
          <ChargeFailedModal {...this.props} errorMessage={this.state.errorMessage} />
        </>
      );
    }

    if (this.props.downgrade) {
      const isRestricted = this.props.planChangeRestrictedToday;
      return (
        <div 
          className={`btn btn-orange ${isRestricted ? 'disabled' : ''}`}
          style={isRestricted ? { opacity: 0.35, cursor: 'not-allowed' } : {}}
          onClick={isRestricted ? this.handleRestrictedClick : this.onDowngrade}
        >
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
