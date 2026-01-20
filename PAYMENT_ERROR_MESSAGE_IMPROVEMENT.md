# 決済エラーメッセージの改善

## 📋 要望

ユーザーからの要望：
1. `error_message`に記録されている内容（例：`Payment setup failed: カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。Your card was declined.`）をユーザー側のエラーメッセージとして表示したい
2. DBの`error_message`には、ユーザーに案内したメッセージと実際の生のエラーメッセージを両方記録したい

## ✅ 実施した修正

### 1. Subscriptions::Charge - エラーメッセージの詳細化

**ファイル**: `app/interactions/subscriptions/charge.rb`

**修正内容**:
`error_message`カラムに、ユーザー向けメッセージと生のStripeエラーメッセージを両方記録するように変更。

#### Stripe::CardError の場合

**変更前**:
```ruby
charge.error_message = "Card error: #{error_message} (code: #{stripe_error[:code]})"
```

**変更後**:
```ruby
stripe_error = error.json_body&.dig(:error) || {}
raw_error_message = stripe_error[:message] || error.message
user_friendly_message = I18n.t("activemodel.errors.models.plan.attributes.base.auth_failed")

# ユーザー向けメッセージと生のエラーを両方記録
charge.error_message = "#{user_friendly_message} | Raw error: #{raw_error_message} (code: #{stripe_error[:code]})"
```

**記録例**:
```
支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card was declined. (code: card_declined)
```

---

#### Stripe::StripeError の場合

**変更後**:
```ruby
stripe_error = error.json_body&.dig(:error) || {}
raw_error_message = stripe_error[:message] || error.message
user_friendly_message = I18n.t("activemodel.errors.models.plan.attributes.base.processor_failed")

# ユーザー向けメッセージと生のエラーを両方記録
charge.error_message = "#{user_friendly_message} | Raw error: #{raw_error_message} (code: #{stripe_error[:code]})"
```

---

#### PaymentIntent canceled の場合

**変更前**:
```ruby
charge.error_message = "Payment canceled: #{payment_intent.cancellation_reason}"
```

**変更後**:
```ruby
user_friendly_message = I18n.t("activemodel.errors.models.plan.attributes.base.canceled")
# ユーザー向けメッセージと生のエラーを両方記録
charge.error_message = "#{user_friendly_message} | Raw error: #{payment_intent.cancellation_reason}"
```

---

#### その他のエラー

**変更前**:
```ruby
charge.error_message = "Payment intent failed with status: #{payment_intent.status}"
```

**変更後**:
```ruby
user_friendly_message = I18n.t("activemodel.errors.models.plan.attributes.base.auth_failed")
# ユーザー向けメッセージと生のエラーを両方記録
charge.error_message = "#{user_friendly_message} | Raw error: Payment intent failed with status: #{payment_intent.status}"
```

---

#### 予期しないエラー

**変更前**:
```ruby
charge.error_message = "Unexpected error: #{e.class} - #{e.message}"
```

**変更後**:
```ruby
user_friendly_message = I18n.t("activemodel.errors.models.plan.attributes.base.something_wrong")
# ユーザー向けメッセージと生のエラーを両方記録
charge.error_message = "#{user_friendly_message} | Raw error: #{e.class} - #{e.message}"
```

---

### 2. Subscriptions::ManualCharge - StoreStripeCustomer失敗時の詳細化

**ファイル**: `app/interactions/subscriptions/manual_charge.rb`

**修正内容**:
`Payments::StoreStripeCustomer`が失敗した場合も、ユーザー向けメッセージと生のStripeエラーを両方記録。

**変更前**:
```ruby
failed_charge_data = {
  # ...
  error_message: "Payment setup failed: #{store_customer_outcome.errors.full_messages.join(', ')}"
}
```

**変更後**:
```ruby
# エラー詳細を取得
user_error = store_customer_outcome.errors.details[:user]&.first || {}
raw_stripe_message = user_error[:stripe_error_message]
user_friendly_message = store_customer_outcome.errors.full_messages.join(', ')

# エラーメッセージにはユーザー向けメッセージと生のStripeエラーを両方含める
combined_error_message = if raw_stripe_message.present?
  "#{user_friendly_message} | Raw error: #{raw_stripe_message}"
else
  user_friendly_message
end

failed_charge_data = {
  # ...
  error_message: combined_error_message
}
```

**記録例**:
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card was declined.
```

---

### 3. PaymentsController - 詳細なエラーメッセージをレスポンスに含める

**ファイル**: `app/controllers/lines/user_bot/settings/payments_controller.rb`

**修正内容**:
APIレスポンスの`message`フィールドに、ユーザー向けメッセージと生のStripeエラーを組み合わせた詳細なメッセージを含める。

**変更前**:
```ruby
render json: {
   message: outcome.errors.full_messages.join(""),
   error_type: error_type,
   stripe_error_code: stripe_error_code,
   stripe_error_message: stripe_error_message,
   # ...
}, status: :unprocessable_entity
```

**変更後**:
```ruby
# ユーザー向けメッセージと生のエラーを組み合わせた詳細なメッセージを作成
user_friendly_message = outcome.errors.full_messages.join("")
detailed_message = if stripe_error_message.present?
  "#{user_friendly_message} #{stripe_error_message}"
else
  user_friendly_message
end

render json: {
   message: detailed_message,
   error_type: error_type,
   stripe_error_code: stripe_error_code,
   stripe_error_message: stripe_error_message,
   # ...
}, status: :unprocessable_entity
```

**レスポンス例**:
```json
{
  "message": "カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 Your card was declined.",
  "error_type": "auth_failed",
  "stripe_error_code": "card_declined",
  "stripe_error_message": "Your card was declined.",
  "client_secret": null,
  "payment_intent_id": null,
  "setup_intent_id": null
}
```

---

### 4. フロントエンド - 詳細なエラーメッセージを表示

**ファイル**: `app/webpacker/javascripts/components/management/plans/charge.js`

**修正内容**:
バックエンドから返される`message`フィールドをそのまま使用し、既にユーザー向けメッセージと生のエラーが含まれているため、追加の加工は不要に。

#### client_secretがない場合のエラー処理

**変更前**:
```javascript
let errorMessage = err.stripe_error_message || err.message || "決済に失敗しました。";

// Stripeエラーコードがあれば追加
if (err.stripe_error_code) {
  errorMessage += `\n\nエラーコード: ${err.stripe_error_code}`;
}

// エラータイプがあれば追加（デバッグ用）
if (err.error_type) {
  errorMessage += `\nエラータイプ: ${err.error_type}`;
}

throw new Error(errorMessage);
```

**変更後**:
```javascript
// messageには既にユーザー向けメッセージとStripeエラーの両方が含まれている
let errorMessage = err.message || "決済に失敗しました。";

throw new Error(errorMessage);
```

---

#### その他のHTTPエラーの場合

**変更前**:
```javascript
const errorData = await response.json();
// Stripe固有のエラーメッセージを優先
errorMessage = errorData.stripe_error_message || errorData.message || errorMessage;

// エラーコードも表示
if (errorData.stripe_error_code) {
  errorMessage += `\n\nエラーコード: ${errorData.stripe_error_code}`;
}
```

**変更後**:
```javascript
const errorData = await response.json();
// messageには既にユーザー向けメッセージとStripeエラーの両方が含まれている
errorMessage = errorData.message || errorMessage;
```

---

#### リトライ失敗時のエラー処理

**変更前**:
```javascript
const errorData = await retryResponse.json();
// Stripe固有のエラーメッセージを優先
errorMessage = errorData.stripe_error_message || errorData.message || errorMessage;
// エラーコードも表示
if (errorData.stripe_error_code) {
  errorMessage += ` (エラーコード: ${errorData.stripe_error_code})`;
}
```

**変更後**:
```javascript
const errorData = await retryResponse.json();
// messageには既にユーザー向けメッセージとStripeエラーの両方が含まれている
errorMessage = errorData.message || errorMessage;
```

---

### 5. フロントエンド - エラーモーダルでの表示

**ファイル**: `app/webpacker/javascripts/components/management/plans/charge_failed.js`

**現状**: 既に`errorMessage`を適切に表示している実装になっているため、変更不要。

```javascript
<div style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word', marginBottom: '15px', padding: '10px', backgroundColor: '#f9f9f9', borderRadius: '4px', fontSize: '14px' }}>
  <strong>エラー詳細:</strong><br/>
  {errorMessage}
</div>
```

---

## 📊 エラーメッセージの記録例

### 例1: カード拒否エラー

#### DBの`subscription_charges.error_message`
```
支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card was declined. (code: card_declined)
```

#### ユーザーへの表示
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 Your card was declined.
```

---

### 例2: カード残高不足

#### DBの`subscription_charges.error_message`
```
支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card has insufficient funds. (code: insufficient_funds)
```

#### ユーザーへの表示
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 Your card has insufficient funds.
```

---

### 例3: カード登録エラー

#### DBの`subscription_charges.error_message`
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card's security code is incorrect.
```

#### ユーザーへの表示
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 Your card's security code is incorrect.
```

---

## 🎯 メリット

### 1. ユーザーにとって親切
- 日本語の丁寧なメッセージと、Stripeの具体的なエラーメッセージの両方が表示される
- 何が問題なのかが明確になり、解決策がわかりやすい

### 2. 開発者・サポートにとって便利
- DBに記録されたエラーメッセージを見るだけで、ユーザーに表示されたメッセージと生のエラーの両方がわかる
- デバッグが容易になる
- ユーザーからスクショをもらった際、エラー内容が詳細にわかる

### 3. 記録の完全性
- すべてのエラーケースで、ユーザー向けメッセージと生のエラーの両方が記録される
- トラブルシューティングが効率的になる

---

## 🚀 確認方法

### テスト用カード番号（Stripe提供）

#### カード拒否エラー
```
カード番号: 4000 0000 0000 0002
CVV: 任意の3桁
有効期限: 未来の日付
```

#### 残高不足エラー
```
カード番号: 4000 0000 0000 9995
CVV: 任意の3桁
有効期限: 未来の日付
```

#### CVCエラー
```
カード番号: 4000 0000 0000 0127
CVV: 任意の3桁
有効期限: 未来の日付
```

### 確認SQL
```sql
-- 最新のエラーを確認
SELECT 
  id,
  user_id,
  state,
  error_message,
  created_at
FROM subscription_charges
WHERE state IN ('auth_failed', 'processor_failed')
  AND error_message IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;
```

---

## 📝 修正したファイル一覧

### バックエンド
1. ✅ `app/interactions/subscriptions/charge.rb` - エラーメッセージの詳細化
2. ✅ `app/interactions/subscriptions/manual_charge.rb` - StoreStripeCustomer失敗時の詳細化
3. ✅ `app/controllers/lines/user_bot/settings/payments_controller.rb` - 詳細なメッセージをレスポンスに含める

### フロントエンド
4. ✅ `app/webpacker/javascripts/components/management/plans/charge.js` - メッセージの簡潔化（詳細は既にバックエンドで組み立て済み）
5. ✅ `app/webpacker/javascripts/components/management/plans/charge_failed.js` - （変更不要、既に適切に実装済み）

### ドキュメント
6. ✅ `PAYMENT_ERROR_MESSAGE_IMPROVEMENT.md` - （このファイル）

---

**作成日**: 2026-01-20  
**対応者**: AI Assistant  
**ステータス**: ✅ 実装完了、動作確認待ち
