# DBのerror_messageに生のエラーを確実に記録する修正

## 🐛 問題

DBの`subscription_charges.error_message`に「親切なメッセージ」のみが記録され、「生のエラー情報」が記録されていなかった。

**期待**:
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card was declined. (code: card_declined)
```

**実際**:
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。
```

---

## 🔍 根本原因

### 1. ロケールファイルの問題

**ファイル**: `config/locales/ja.yml`

**問題のコード**:
```yaml
payments/store_stripe_customer:
  attributes:
    user:
      auth_failed: "^カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。%{stripe_error_message}"
```

`%{stripe_error_message}`というプレースホルダーがあるが、`errors.full_messages`を使うと正しく展開されない。

### 2. ManualChargeでの問題

**ファイル**: `app/interactions/subscriptions/manual_charge.rb`

**問題のコード**:
```ruby
user_friendly_message = store_customer_outcome.errors.full_messages.join(', ')
# → full_messagesでは%{stripe_error_message}が展開されない
```

### 3. Chargeでの詳細不足

**ファイル**: `app/interactions/subscriptions/charge.rb`

**問題のコード**:
```ruby
# requires_payment_methodのケース
charge.error_message = "#{user_friendly_message} | Raw error: Payment intent status: #{payment_intent.status}"
# → statusだけで、詳細なエラーメッセージがない
```

---

## ✅ 修正内容

### 1. ロケールファイルの修正

**ファイル**: `config/locales/ja.yml`

**修正前**:
```yaml
auth_failed: "^カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。%{stripe_error_message}"
```

**修正後**:
```yaml
auth_failed: "^カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。"
```

**理由**: プレースホルダーを削除し、コード内で手動でメッセージを組み立てる。

---

### 2. ManualChargeの修正

**ファイル**: `app/interactions/subscriptions/manual_charge.rb`

**修正前**:
```ruby
user_error = store_customer_outcome.errors.details[:user]&.first || {}
raw_stripe_message = user_error[:stripe_error_message]
user_friendly_message = store_customer_outcome.errors.full_messages.join(', ')

combined_error_message = if raw_stripe_message.present?
  "#{user_friendly_message} | Raw error: #{raw_stripe_message}"
else
  user_friendly_message
end
```

**修正後**:
```ruby
# エラー詳細を取得
user_error = store_customer_outcome.errors.details[:user]&.first || {}
customer_error = store_customer_outcome.errors.details[:customer]&.first || {}

# エラータイプとStripeエラー情報を取得
error_type = user_error[:error] || customer_error[:error]
raw_stripe_message = user_error[:stripe_error_message] || customer_error[:stripe_error_message]
stripe_error_code = user_error[:stripe_error_code] || customer_error[:stripe_error_code]

# ユーザー向けメッセージを生成（full_messagesは使わない）
user_friendly_message = if error_type == :auth_failed
  I18n.t("activemodel.errors.models.payments/store_stripe_customer.attributes.user.auth_failed")
elsif error_type == :processor_failed
  I18n.t("activemodel.errors.models.payments/store_stripe_customer.attributes.user.processor_failed")
elsif error_type == :requires_action
  I18n.t("activemodel.errors.models.payments/store_stripe_customer.attributes.user.requires_action")
else
  store_customer_outcome.errors.full_messages.join(', ')
end

# エラーメッセージにはユーザー向けメッセージと生のStripeエラーを両方含める
combined_error_message = if raw_stripe_message.present?
  error_details = "#{raw_stripe_message}"
  error_details += " (code: #{stripe_error_code})" if stripe_error_code.present?
  "#{user_friendly_message} | Raw error: #{error_details}"
else
  user_friendly_message
end
```

**改善点**:
- `full_messages`を使わずに、`I18n.t`で直接ロケールから取得
- `error_type`を判定してメッセージを選択
- `stripe_error_code`も含める

---

### 3. Chargeの詳細情報追加

**ファイル**: `app/interactions/subscriptions/charge.rb`

#### requires_payment_methodのケース

**修正前**:
```ruby
charge.error_message = "#{user_friendly_message} | Raw error: Payment intent status: #{payment_intent.status}"
```

**修正後**:
```ruby
error_details = "Payment intent status: #{payment_intent.status}"
error_details += ", last_payment_error: #{payment_intent.last_payment_error&.dig('message')}" if payment_intent.last_payment_error.present?
charge.error_message = "#{user_friendly_message} | Raw error: #{error_details}"
```

---

#### canceledのケース

**修正前**:
```ruby
charge.error_message = "#{user_friendly_message} | Raw error: #{payment_intent.cancellation_reason}"
```

**修正後**:
```ruby
error_details = "Cancellation reason: #{payment_intent.cancellation_reason || 'not specified'}"
error_details += ", last_payment_error: #{payment_intent.last_payment_error&.dig('message')}" if payment_intent.last_payment_error.present?
charge.error_message = "#{user_friendly_message} | Raw error: #{error_details}"
```

---

#### elseブロック（その他の失敗）

**修正前**:
```ruby
charge.error_message = "#{user_friendly_message} | Raw error: Payment intent failed with status: #{payment_intent.status}"
```

**修正後**:
```ruby
error_details = "Payment intent failed with status: #{payment_intent.status}"
error_details += ", last_payment_error: #{payment_intent.last_payment_error&.dig('message')}" if payment_intent.last_payment_error.present?
charge.error_message = "#{user_friendly_message} | Raw error: #{error_details}"
```

---

#### no_payment_methodのケース

**修正前**:
```ruby
charge.error_message = "Failed to create payment intent: #{errors.full_messages.join(', ')}"
```

**修正後**:
```ruby
user_friendly_message = I18n.t("activemodel.errors.models.plan.attributes.base.no_payment_method")
raw_error = errors.full_messages.join(', ')
charge.error_message = "#{user_friendly_message} | Raw error: Failed to create payment intent - #{raw_error}"
```

---

## 📊 記録例

### 例1: カード拒否エラー（StoreStripeCustomer）

#### DB記録 (`subscription_charges.error_message`)
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card was declined. (code: card_declined)
```

#### フロント表示
```
カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。
```

---

### 例2: 3DS認証が必要（Charge）

#### DB記録 (`subscription_charges.error_message`)
```
3Dセキュア認証が必要です。カード発行会社の認証を完了してください。 | Raw error: Payment intent status: requires_action, last_payment_error: Card authentication failed
```

#### フロント表示
```
3Dセキュア認証が必要です。カード発行会社の認証を完了してください。
```

---

### 例3: カード残高不足（Charge）

#### DB記録 (`subscription_charges.error_message`)
```
支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。 | Raw error: Your card has insufficient funds. (code: insufficient_funds)
```

#### フロント表示
```
支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。
```

---

### 例4: 決済キャンセル

#### DB記録 (`subscription_charges.error_message`)
```
支払いがキャンセルされました。 | Raw error: Cancellation reason: abandoned, last_payment_error: Payment was canceled by the user
```

#### フロント表示
```
支払いがキャンセルされました。
```

---

### 例5: 支払い方法なし

#### DB記録 (`subscription_charges.error_message`)
```
有効な支払い方法が見つかりません。 | Raw error: Failed to create payment intent - User does not have a valid payment method
```

#### フロント表示
```
有効な支払い方法が見つかりません。
```

---

## 🎯 修正の要点

### 1. full_messagesを使わない
- `full_messages`はロケールの`%{}`プレースホルダーを正しく展開しない場合がある
- `I18n.t`で直接ロケールから取得する

### 2. error_typeで判定
- `errors.details`から`error_type`を取得
- 適切なロケールキーを選択

### 3. 詳細情報を含める
- `stripe_error_message`だけでなく、`stripe_error_code`も含める
- `payment_intent.last_payment_error`も含める
- `cancellation_reason`などの追加情報も含める

### 4. 一貫性
- すべてのエラーケースで同じフォーマット：
  ```
  {ユーザー向けメッセージ} | Raw error: {詳細なエラー情報}
  ```

---

## 📝 修正したファイル

1. ✅ `config/locales/ja.yml` - プレースホルダーを削除
2. ✅ `app/interactions/subscriptions/manual_charge.rb` - `I18n.t`で直接取得、詳細情報追加
3. ✅ `app/interactions/subscriptions/charge.rb` - すべてのケースで詳細情報追加

---

**作成日**: 2026-01-20  
**対応者**: AI Assistant  
**ステータス**: ✅ 実装完了、動作確認待ち
