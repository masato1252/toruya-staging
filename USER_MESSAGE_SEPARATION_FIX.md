# ユーザー向けメッセージとDB記録の分離

## 📋 要望

### 現状の問題
- **chargesのerror_message**: `3Dセキュア認証が必要です。カード発行会社の認証を完了してください。`（親切）
- **フロント側表示**: `Invalid value for stripe.confirmCardPayment intent secret: value should be a PaymentIntent client secret. You specified: a SetupIntent client secret.`（技術的すぎる）

### 理想の状態
1. **フロント側表示**: ユーザー向けの親切なメッセージのみ表示
   - 例: `3Dセキュア認証が必要です。カード発行会社の認証を完了してください。`
2. **chargesのerror_message**: ユーザー向けメッセージ + 生のエラーの両方を記録
   - 例: `3Dセキュア認証が必要です。カード発行会社の認証を完了してください。 | Raw error: Payment intent status: requires_action`

---

## ✅ 実施した修正

### 1. Subscriptions::Charge - user_messageの追加

**ファイル**: `app/interactions/subscriptions/charge.rb`

#### requires_payment_method の場合

**変更前**:
```ruby
when "requires_payment_method", "requires_source", "requires_confirmation", "requires_action", ...
  charge.stripe_charge_details = payment_intent.as_json
  charge.save!
  errors.add(:plan, :requires_payment_method, 
    client_secret: payment_intent.client_secret, 
    payment_intent_id: payment_intent.id
  )
```

**変更後**:
```ruby
when "requires_payment_method", "requires_source", "requires_confirmation", "requires_action", ...
  charge.stripe_charge_details = payment_intent.as_json
  user_friendly_message = I18n.t("activemodel.errors.models.plan.attributes.base.requires_payment_method")
  # ユーザー向けメッセージと生のエラーを両方記録
  charge.error_message = "#{user_friendly_message} | Raw error: Payment intent status: #{payment_intent.status}"
  charge.save!
  errors.add(:plan, :requires_payment_method, 
    client_secret: payment_intent.client_secret, 
    payment_intent_id: payment_intent.id,
    user_message: user_friendly_message  # ← 追加
  )
```

---

#### auth_failed の場合

**変更後**:
```ruby
errors.add(:plan, :auth_failed, 
  stripe_error_code: stripe_error[:code],
  stripe_error_message: raw_error_message,
  user_message: user_friendly_message  # ← 追加
)
```

---

#### processor_failed の場合

**変更後**:
```ruby
errors.add(:plan, :processor_failed,
  stripe_error_code: stripe_error[:code],
  stripe_error_message: raw_error_message,
  user_message: user_friendly_message  # ← 追加
)
```

---

### 2. Payments::StoreStripeCustomer - user_messageの追加

**ファイル**: `app/interactions/payments/store_stripe_customer.rb`

#### SetupIntent の requires_action

**変更前**:
```ruby
when 'requires_action', 'requires_payment_method', 'requires_confirmation'
  errors.add(:user, :requires_action, 
    client_secret: setup_intent.client_secret, 
    setup_intent_id: setup_intent.id
  )
```

**変更後**:
```ruby
when 'requires_action', 'requires_payment_method', 'requires_confirmation'
  user_friendly_message = I18n.t("activemodel.errors.models.payments/store_stripe_customer.attributes.user.requires_action")
  errors.add(:user, :requires_action, 
    client_secret: setup_intent.client_secret, 
    setup_intent_id: setup_intent.id,
    user_message: user_friendly_message  # ← 追加
  )
```

---

#### PaymentIntent の requires_action

**変更後**:
```ruby
when 'requires_action', 'requires_payment_method', 'requires_confirmation', ...
  user_friendly_message = I18n.t("activemodel.errors.models.payments/store_stripe_customer.attributes.user.requires_action")
  errors.add(:user, :requires_action, 
    client_secret: payment_intent.client_secret, 
    payment_intent_id: payment_intent_id,
    user_message: user_friendly_message  # ← 追加
  )
```

---

#### Customer の requires_action

**変更後**:
```ruby
when 'requires_action', 'requires_payment_method', 'requires_confirmation', ...
  user_friendly_message = I18n.t("activemodel.errors.models.payments/store_stripe_customer.attributes.customer.requires_action")
  errors.add(:customer, :requires_action, 
    client_secret: setup_intent.client_secret, 
    payment_intent_id: setup_intent.id,
    user_message: user_friendly_message  # ← 追加
  )
```

---

### 3. PaymentsController - user_messageを優先的に使用

**ファイル**: `app/controllers/lines/user_bot/settings/payments_controller.rb`

**変更前**:
```ruby
# Stripeエラーコードとメッセージを取得（planとuserの両方をチェック）
stripe_error_code = plan_error[:stripe_error_code] || user_error[:stripe_error_code]
stripe_error_message = plan_error[:stripe_error_message] || user_error[:stripe_error_message]

# ユーザー向けメッセージと生のエラーを組み合わせた詳細なメッセージを作成
user_friendly_message = outcome.errors.full_messages.join("")
detailed_message = if stripe_error_message.present?
  "#{user_friendly_message} #{stripe_error_message}"
else
  user_friendly_message
end

render json: {
   message: detailed_message,
   # ...
}
```

**変更後**:
```ruby
# Stripeエラーコードとメッセージを取得（planとuserの両方をチェック）
stripe_error_code = plan_error[:stripe_error_code] || user_error[:stripe_error_code]
stripe_error_message = plan_error[:stripe_error_message] || user_error[:stripe_error_message]
user_message = plan_error[:user_message] || user_error[:user_message]

# ユーザー向けメッセージのみをフロントに送信（詳細はDBに記録済み）
display_message = user_message || outcome.errors.full_messages.join("")

render json: {
   message: display_message,
   # ...
}
```

---

### 4. フロントエンド - シンプルなエラー表示

**ファイル**: `app/webpacker/javascripts/components/management/plans/charge.js`

**変更前**:
```javascript
catch (err) {
  this.toggleProcessing()
  
  let errorMessage = err.message || (typeof err === 'string' ? err : "決済に失敗しました。");
  
  // Stripeの生のエラーメッセージをユーザーフレンドリーなメッセージに変換
  if (errorMessage.includes('Invalid value for stripe.confirmCardPayment')) {
    errorMessage = "カード情報の処理中にエラーが発生しました。もう一度お試しいただくか、別のカードをご利用ください。";
  } else if (errorMessage.includes('Invalid value for stripe.confirmCardSetup')) {
    errorMessage = "カード登録の処理中にエラーが発生しました。もう一度お試しいただくか、別のカードをご利用ください。";
  }
  
  if (err.code && !errorMessage.includes('エラーコード')) {
    errorMessage += `\n\nエラーコード: ${err.code}`;
  }
  if (err.decline_code) {
    errorMessage += `\n拒否コード: ${err.decline_code}`;
  }
  
  console.error('Payment error details:', err);
  
  this.setState({ errorMessage });
  $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
}
```

**変更後**:
```javascript
catch (err) {
  this.toggleProcessing()
  
  // エラーメッセージを取得（バックエンドからのユーザーフレンドリーなメッセージ）
  let errorMessage = err.message || (typeof err === 'string' ? err : "決済に失敗しました。もう一度お試しください。");
  
  // デバッグ用にコンソールに詳細を出力
  console.error('Payment error details:', err);
  
  // エラーメッセージをstateに保存してモーダルに渡す
  this.setState({ errorMessage });
  $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
}
```

---

## 📊 データフローの改善

### 修正前のフロー

```
1. エラー発生
   ↓
2. Interaction: errors.add(:plan, :auth_failed, stripe_error_message: "Your card was declined.")
   ↓
3. Controller: message = "#{user_friendly} #{stripe_error_message}"
   ↓
4. Frontend: 受け取ったメッセージをそのまま表示
   ↓
5. User sees: "支払いに失敗しました。Your card was declined."
```

### 修正後のフロー

```
1. エラー発生
   ↓
2. Interaction: 
   - charge.error_message = "支払いに失敗しました。 | Raw error: Your card was declined. (code: card_declined)"
   - errors.add(:plan, :auth_failed, 
       stripe_error_message: "Your card was declined.",
       user_message: "支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。"
     )
   ↓
3. Controller: message = user_message (ユーザー向けメッセージのみ)
   ↓
4. Frontend: 受け取ったメッセージをそのまま表示
   ↓
5. User sees: "支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。"
   ↓
6. DB (subscription_charges.error_message): 
   "支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card was declined. (code: card_declined)"
```

---

## 📊 具体例

### 例1: 3DS認証が必要な場合

#### DBの記録 (`subscription_charges.error_message`)
```
3Dセキュア認証が必要です。カード発行会社の認証を完了してください。 | Raw error: Payment intent status: requires_action
```

#### ユーザーへの表示
```
3Dセキュア認証が必要です。カード発行会社の認証を完了してください。
```

---

### 例2: カード拒否エラー

#### DBの記録 (`subscription_charges.error_message`)
```
支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card was declined. (code: card_declined)
```

#### ユーザーへの表示
```
支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。
```

---

### 例3: カード登録エラー

#### DBの記録 (`subscription_charges.error_message`)
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card's security code is incorrect.
```

#### ユーザーへの表示
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。
```

---

## 🎯 メリット

### 1. ユーザー体験の向上
- 技術的な詳細が表示されない
- わかりやすい日本語のメッセージのみ
- 次に何をすべきかが明確

### 2. デバッグの容易さ
- DBには詳細な情報が記録される
- ユーザー向けメッセージと生のエラーの両方が確認できる
- スクショから問題を特定しやすい

### 3. 保守性の向上
- バックエンドでメッセージを一元管理
- フロントエンドはシンプルに
- エラーメッセージの変更が容易

---

## 📝 修正したファイル一覧

### バックエンド
1. ✅ `app/interactions/subscriptions/charge.rb` - user_messageを追加
2. ✅ `app/interactions/payments/store_stripe_customer.rb` - user_messageを追加
3. ✅ `app/controllers/lines/user_bot/settings/payments_controller.rb` - user_messageを優先的に使用

### フロントエンド
4. ✅ `app/webpacker/javascripts/components/management/plans/charge.js` - シンプルなエラー表示

### ドキュメント
5. ✅ `USER_MESSAGE_SEPARATION_FIX.md` - （このファイル）

---

**作成日**: 2026-01-20  
**対応者**: AI Assistant  
**ステータス**: ✅ 実装完了、動作確認待ち
