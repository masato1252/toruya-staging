# 新規有料プラン契約時にRollbarに上がらない決済エラー - 調査レポート

## 🔍 調査結果：Rollbarに上がらない可能性のある決済エラー

### 1. ⚠️ **3DS認証が必要な場合（requires_action系）**

**場所**: `app/interactions/subscriptions/charge.rb:81-85`

```ruby
when "requires_payment_method", "requires_source", "requires_confirmation", "requires_action", "processing", "requires_capture", "requires_source_action"
  # 3DS認証が必要な場合、chargeは保存するがdetailsは作成しない
  charge.stripe_charge_details = payment_intent.as_json
  charge.save!
  errors.add(:plan, :requires_payment_method, client_secret: payment_intent.client_secret, payment_intent_id: payment_intent.id)
```

**問題点**: 
- **Rollbarに記録されない**
- エラーは返されるが、ユーザーが3DS認証を完了しない場合、決済は完了しない
- フロントエンドで3DS処理が失敗する可能性

**影響**: ユーザーは「決済できない」と感じるが、システム側ではエラーと認識されない

---

### 2. ⚠️ **canceled状態の場合**

**場所**: `app/interactions/subscriptions/charge.rb:86-88`

```ruby
when "canceled"
  # 決済失敗時はchargeを保存しない（ロールバックされる）
  errors.add(:plan, :canceled, client_secret: payment_intent.client_secret)
```

**問題点**: 
- **Rollbarに記録されない**
- PaymentIntentがキャンセル状態になった場合、単にエラーを返すのみ

**影響**: Stripe側で何らかの理由でキャンセルされた決済が追跡できない

---

### 3. ⚠️ **開発環境でのエラー**

**場所**: `app/interactions/subscriptions/charge.rb:111-114`, `125-128`

```ruby
if Rails.configuration.x.env.production?
  SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, #{error}")
  Rollbar.error(error, user_id: user.id, stripe_charge: error.json_body[:error])
end
```

**問題点**: 
- **開発環境・ステージング環境ではRollbarに記録されない**
- テスト決済の失敗が追跡できない

**影響**: 本番デプロイ前に問題を発見できない

---

### 4. ⚠️ **Payments::StoreStripeCustomer での "already been attached" エラー**

**場所**: `app/interactions/payments/store_stripe_customer.rb:145-150`

```ruby
rescue Stripe::StripeError => error
  if !error.message.include?("already been attached")
    errors.add(:user, :processor_failed)
    Rollbar.error(error, toruya_user: user.id, stripe_charge: error.json_body&.dig(:error))
  end
  nil
end
```

**問題点**: 
- **"already been attached" エラーは意図的にRollbarに記録されない**
- しかし、このエラーが発生すると決済は失敗する
- エラーメッセージに "already been attached" が含まれる場合、完全に無視される

**影響**: 
- 支払い方法が既に別の顧客に紐付いている場合、エラーが追跡されない
- ユーザーは決済できないが、原因が分からない

---

### 5. ⚠️ **create_payment_intent で nil が返される場合**

**場所**: `app/interactions/subscriptions/charge.rb:148-164`

```ruby
def create_payment_intent(amount, description, charge, charging_rank, order_id)
  stripe_customer_id = user.subscription&.stripe_customer_id
  if stripe_customer_id.blank?
    errors.add(:plan, :no_stripe_customer)
    return nil  # ← Rollbarに記録されずnilを返す
  end

  if manual
    selected_payment_method = get_selected_payment_method(stripe_customer_id, payment_method_id)
    
    if selected_payment_method.nil?
      errors.add(:plan, :stripe_customer_not_found)
      Rollbar.error("No payment method available", user_id: user.id, stripe_customer_id: stripe_customer_id)
      return nil
    end
```

**問題点**:
- `stripe_customer_id.blank?` の場合、**Rollbarに記録されない**
- エラーは追加されるが、なぜStripe顧客IDがないのか原因が追跡できない

**影響**: 
- 新規ユーザーで顧客情報の作成に失敗している場合が追跡できない
- StoreStripeCustomer が失敗した後、このエラーになる可能性がある

---

### 6. ⚠️ **json_body が nil の場合のエラー**

**場所**: `app/interactions/subscriptions/charge.rb:103-107`, `117-121`

```ruby
rescue Stripe::CardError => error
  stripe_error = error.json_body[:error] || {}  # ← json_bodyがnilの場合エラー
  errors.add(:plan, :auth_failed, 
    stripe_error_code: stripe_error[:code],
    stripe_error_message: stripe_error[:message] || error.message
  )
```

**問題点**:
- `error.json_body` が nil の場合、`NoMethodError` が発生する可能性
- この場合、外側の `rescue => e` でキャッチされるが、元のStripeエラーの詳細が失われる

**影響**: 
- Stripeエラーの詳細が正しく記録されない可能性
- デバッグが困難になる

---

### 7. ⚠️ **コントローラーレベルでのエラーハンドリング**

**場所**: `app/controllers/lines/user_bot/settings/payments_controller.rb:110-116`

```ruby
if outcome.invalid?
  Rollbar.error(
    "Payment create failed",
    errors_messages: outcome.errors.full_messages.join(", "),
    errors_details: outcome.errors.details,
    params: params
  )
```

**問題点**:
- コントローラーでは記録されるが、Interactionレベルでは記録されないエラーがある
- `params` にトークン情報が含まれる可能性（セキュリティリスク）

---

## 📊 優先度別の問題リスト

### 🔴 高優先度（すぐに対応すべき）

1. **3DS認証必要時にRollbarに記録されない** → ユーザー体験に直結
2. **"already been attached" エラーが無視される** → 決済失敗の原因が追跡できない
3. **開発環境でRollbarに記録されない** → テスト時に問題を発見できない
4. **stripe_customer_id.blank? の場合にRollbarに記録されない** → 根本原因が追跡できない

### 🟡 中優先度

5. **json_body が nil の場合のエラー処理** → エッジケースでエラー詳細が失われる
6. **canceled 状態の記録不足** → まれなケースだが追跡は必要

### 🟢 低優先度（観察・改善）

7. **コントローラーでのparamsログ** → セキュリティ改善の余地

---

## 💡 推奨される対応策

### 1. 3DS認証関連のログ追加

```ruby
when "requires_payment_method", "requires_source", "requires_confirmation", "requires_action", "processing", "requires_capture", "requires_source_action"
  # ログに記録を追加
  Rollbar.info("Payment requires action", 
    user_id: user.id, 
    status: payment_intent.status,
    payment_intent_id: payment_intent.id
  )
  charge.stripe_charge_details = payment_intent.as_json
  charge.save!
  errors.add(:plan, :requires_payment_method, client_secret: payment_intent.client_secret, payment_intent_id: payment_intent.id)
```

### 2. "already been attached" エラーも記録

```ruby
rescue Stripe::StripeError => error
  if error.message.include?("already been attached")
    # 警告レベルで記録（エラーではないが追跡は必要）
    Rollbar.warning("Payment method already attached", toruya_user: user.id, error_message: error.message)
    errors.add(:user, :payment_method_already_attached)
  else
    errors.add(:user, :processor_failed)
    Rollbar.error(error, toruya_user: user.id, stripe_charge: error.json_body&.dig(:error))
  end
  nil
end
```

### 3. 環境に関係なくRollbarに記録

```ruby
# Rails.configuration.x.env.production? の条件を削除
rescue Stripe::CardError => error
  stripe_error = error.json_body&.dig(:error) || {}
  errors.add(:plan, :auth_failed, 
    stripe_error_code: stripe_error[:code],
    stripe_error_message: stripe_error[:message] || error.message
  )
  
  handle_charge_failed(charge)
  
  # 常にRollbarに記録（環境別にログレベルを変えることは可能）
  Rollbar.error(error, user_id: user.id, stripe_charge: stripe_error, env: Rails.env)
  
  if Rails.configuration.x.env.production?
    SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, #{error}")
  end
end
```

### 4. stripe_customer_id が空の場合を明示的に記録

```ruby
if stripe_customer_id.blank?
  Rollbar.error("No Stripe customer ID", 
    user_id: user.id, 
    subscription_id: user.subscription&.id,
    subscription_created_at: user.subscription&.created_at
  )
  errors.add(:plan, :no_stripe_customer)
  return nil
end
```

### 5. canceled 状態も記録

```ruby
when "canceled"
  Rollbar.warning("Payment intent canceled", 
    user_id: user.id, 
    payment_intent_id: payment_intent.id,
    payment_intent_json: payment_intent.as_json
  )
  errors.add(:plan, :canceled, client_secret: payment_intent.client_secret)
```

---

## 🎯 即座に確認すべきこと

1. **Stripeダッシュボード**で失敗した決済を確認
   - PaymentIntentのステータスを確認
   - エラーメッセージを確認
   
2. **データベース**で `subscription_charges` テーブルを確認
   - `state` が `incomplete` や `failed` のレコードを検索
   - `stripe_charge_details` の内容を確認

3. **ユーザーの subscription レコード**を確認
   - `stripe_customer_id` の有無
   - `trial_expired_date` の値
   - `expired_date` の値

4. **ブラウザのコンソールログ**を確認
   - フロントエンドで3DS処理がエラーになっていないか

---

## 📝 調査用SQLクエリ

```sql
-- 失敗した決済を確認
SELECT 
  sc.id,
  sc.user_id,
  sc.state,
  sc.created_at,
  sc.stripe_charge_details->>'status' as stripe_status,
  sc.stripe_charge_details->>'last_payment_error' as last_error
FROM subscription_charges sc
WHERE sc.state IN ('incomplete', 'failed', 'auth_failed', 'processor_failed')
  AND sc.created_at > NOW() - INTERVAL '7 days'
ORDER BY sc.created_at DESC;

-- Stripe顧客IDがないサブスクリプションを確認
SELECT 
  s.id,
  s.user_id,
  s.stripe_customer_id,
  s.trial_expired_date,
  s.created_at,
  u.email
FROM subscriptions s
JOIN users u ON u.id = s.user_id
WHERE s.stripe_customer_id IS NULL
  AND s.created_at > NOW() - INTERVAL '30 days';
```

---

**作成日**: 2026-01-20
**対象**: 新規有料プラン契約時の決済エラー
**優先度**: 🔴 高
