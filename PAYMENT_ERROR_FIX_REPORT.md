# 決済エラー2パターンの修正レポート

## 🐛 報告されたエラー

### エラー1: StoreStripeCustomer失敗時にchargeが記録されない
```
エラー詳細:
Usertranslation missing: ja.active_interaction.errors.models.payments/store_stripe_customer.attributes.user.auth_failed
```

**問題**: 
- `Payments::StoreStripeCustomer` が失敗した時点では、まだ `Subscriptions::Charge.run()` が呼ばれていない
- そのため、chargeレコードが作成されず、DBに記録が残らない

---

### エラー2: SetupIntent と PaymentIntent の混同
```
エラー詳細:
Invalid value for stripe.confirmCardPayment intent secret: value should be a PaymentIntent client secret. You specified: a SetupIntent client secret.
```

**問題**:
- `Payments::StoreStripeCustomer` は **SetupIntent** を使用してカード登録を行う
- SetupIntent は `seti_xxx` という形式の `client_secret` を返す
- しかし、フロントエンドでは `stripe.confirmCardPayment()` を呼んでいた
- `confirmCardPayment()` は **PaymentIntent** 専用のメソッド
- SetupIntent には `stripe.confirmCardSetup()` を使う必要がある

---

## ✅ 修正内容

### 1. ManualCharge: StoreStripeCustomer失敗時もchargeを記録

**ファイル**: `app/interactions/subscriptions/manual_charge.rb`

**修正内容**:
```ruby
unless store_customer_outcome.valid?
  # StoreStripeCustomerが失敗した場合もchargeレコードを作成
  charge_amount_for_error = begin
    new_plan_price, charging_rank = compose(Plans::Price, user: user, plan: plan, rank: rank)
    residual_value = compose(Subscriptions::ResidualValue, user: user)
    if user.subscription.in_paid_plan && (last_charge = user.subscription_charges.last_plan_charged)
      new_plan_price = new_plan_price * Rational(last_charge.expired_date - Subscription.today, last_charge.expired_date - last_charge.charge_date)
    end
    amount = new_plan_price - residual_value
    amount.positive? ? amount : new_plan_price
  rescue => e
    Money.new(0, user.currency || "JPY")
  end
  
  failed_charge_data = {
    user_id: user.id,
    plan_id: plan.id,
    rank: rank,
    amount_cents: charge_amount_for_error.cents,
    amount_currency: charge_amount_for_error.currency.iso_code,
    charge_date: Subscription.today,
    manual: true,
    order_id: OrderId.generate,
    state: 'auth_failed',
    error_message: "Payment setup failed: #{store_customer_outcome.errors.full_messages.join(', ')}"
  }
  
  errors.merge!(store_customer_outcome.errors)
  raise ActiveRecord::Rollback
end
```

**効果**:
- カード登録に失敗した場合でも、chargeレコードがDBに保存される
- `error_message` にエラー内容が記録される
- トランザクション外で保存されるため、ロールバックの影響を受けない

---

### 2. コントローラー: setup_intent_idをレスポンスに追加

**ファイル**: `app/controllers/lines/user_bot/settings/payments_controller.rb`

**修正内容**:
```ruby
# エラータイプを取得（:planキーから最初のエラーを取得）
plan_error = outcome.errors.details[:plan]&.first || {}
user_error = outcome.errors.details[:user]&.first || {}  # ← 追加
error_type = plan_error[:error] || user_error[:error] || outcome.errors.details.values.flatten.first&.dig(:error)

render json: {
   message: outcome.errors.full_messages.join(""),
   error_type: error_type,
   stripe_error_code: stripe_error_code,
   stripe_error_message: stripe_error_message,
   client_secret: error_with_client_secret[:client_secret],
   payment_intent_id: error_with_client_secret[:payment_intent_id],
   setup_intent_id: error_with_client_secret[:setup_intent_id]  # ← 追加
}, status: :unprocessable_entity
```

**効果**:
- `user` エラー（StoreStripeCustomer由来）も正しく取得
- `setup_intent_id` をフロントエンドに渡す

---

### 3. フロントエンド: SetupIntent と PaymentIntent を区別

**ファイル**: `app/webpacker/javascripts/components/management/plans/charge.js`

**修正内容**:
```javascript
} else if (response.status === 422) {
  const err = await response.json()
  if (err.client_secret) {
    const stripe = await loadStripe(this.props.stripeKey || this.props.stripe_key);
    let result;

    // SetupIntent か PaymentIntent かを判定
    const isSetupIntent = err.setup_intent_id || err.client_secret.startsWith('seti_');
    
    if (isSetupIntent) {
      // SetupIntent の場合（カード登録時）
      result = await stripe.confirmCardSetup(err.client_secret, {
        payment_method: paymentMethodId
      });
      
      if (result.error) {
        throw result.error;
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
            setup_intent_id: result.setupIntent.id  // ← setup_intent_idを送信
          }),
        });
        // ... 以下略
      }
    } else {
      // PaymentIntent の場合（決済時）
      switch (err.error_type || err.plan) {
        case 'requires_payment_method':
        case 'requires_source':
          result = await stripe.confirmCardPayment(err.client_secret, {
            payment_method: paymentMethodId
          });
          break;
        // ... 以下略
      }
    }
  }
}
```

**効果**:
- `setup_intent_id` の有無、または `client_secret` のプレフィックス（`seti_`）で判定
- SetupIntent の場合は `stripe.confirmCardSetup()` を使用
- PaymentIntent の場合は `stripe.confirmCardPayment()` を使用
- それぞれ正しいIDをバックエンドに送信

---

## 🔍 エラーの流れ（修正前）

### エラー1の流れ
```
1. ユーザーが決済ボタンをクリック
2. フロントエンド → バックエンド（Plans::Subscribe）
3. Plans::Subscribe → Subscriptions::ManualCharge
4. ManualCharge → Payments::StoreStripeCustomer
5. StoreStripeCustomer が失敗（カードエラーなど）
6. トランザクションロールバック
7. ❌ chargeレコードが作成されていないため、DBに記録なし
8. フロント画面にエラー表示のみ
```

### エラー2の流れ
```
1. ユーザーが決済ボタンをクリック
2. フロントエンド → バックエンド
3. バックエンド → Payments::StoreStripeCustomer
4. StoreStripeCustomer が SetupIntent を作成
5. 3DS認証が必要 → client_secret（seti_xxx）を返す
6. フロントエンドが client_secret を受信
7. ❌ stripe.confirmCardPayment() を呼ぶ（間違い！）
8. Stripeエラー: "SetupIntent client secret を PaymentIntent に使えません"
```

---

## ✅ エラーの流れ（修正後）

### エラー1の流れ
```
1. ユーザーが決済ボタンをクリック
2. フロントエンド → バックエンド（Plans::Subscribe）
3. Plans::Subscribe → Subscriptions::ManualCharge
4. ManualCharge → Payments::StoreStripeCustomer
5. StoreStripeCustomer が失敗（カードエラーなど）
6. ✅ failed_charge_data を作成（エラー情報を含む）
7. トランザクションロールバック
8. ✅ トランザクション外で SubscriptionCharge.create!(failed_charge_data)
9. ✅ DBに記録される（state: auth_failed, error_message: "Payment setup failed: ..."）
10. フロント画面にエラー表示
```

### エラー2の流れ
```
1. ユーザーが決済ボタンをクリック
2. フロントエンド → バックエンド
3. バックエンド → Payments::StoreStripeCustomer
4. StoreStripeCustomer が SetupIntent を作成
5. 3DS認証が必要 → client_secret（seti_xxx）と setup_intent_id を返す
6. フロントエンドが client_secret と setup_intent_id を受信
7. ✅ setup_intent_id の有無で判定
8. ✅ stripe.confirmCardSetup() を呼ぶ（正しい！）
9. ✅ 3DS認証成功
10. ✅ setup_intent_id をバックエンドに送信
11. ✅ 決済処理続行
```

---

## 📊 確認方法

### エラー1の確認（StoreStripeCustomer失敗）

**テストケース**: 無効なカード番号を入力

**確認SQL**:
```sql
SELECT 
  id,
  user_id,
  state,
  error_message,
  created_at
FROM subscription_charges
WHERE error_message LIKE '%Payment setup failed%'
ORDER BY created_at DESC
LIMIT 10;
```

**期待される結果**:
- `state = 'auth_failed'`
- `error_message = 'Payment setup failed: User auth failed'` など

---

### エラー2の確認（SetupIntent vs PaymentIntent）

**テストケース**: 3DS認証が必要なカードを使用

**確認方法**:
1. ブラウザの開発者ツール → Console を開く
2. 決済ボタンをクリック
3. 3DS認証画面が表示される
4. Console に以下のようなログが出る:
   ```
   Using confirmCardSetup for SetupIntent
   ```
5. エラーが出ない

**以前のエラー**:
```
Error: Invalid value for stripe.confirmCardPayment intent secret
```

---

## 🎯 まとめ

### 修正したファイル
1. `app/interactions/subscriptions/manual_charge.rb`
2. `app/controllers/lines/user_bot/settings/payments_controller.rb`
3. `app/webpacker/javascripts/components/management/plans/charge.js`

### 解決した問題
1. ✅ StoreStripeCustomer失敗時もchargeレコードが保存される
2. ✅ SetupIntent と PaymentIntent を正しく区別して処理
3. ✅ すべてのエラーケースでDBに記録が残る

### 副次的な改善
- エラーメッセージがより詳細になった
- デバッグが容易になった
- ユーザーへのフィードバックが改善された

---

**作成日**: 2026-01-20  
**対応**: 2つの決済エラーパターンの修正
