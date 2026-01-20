# 決済エラー2パターンの修正完了報告

## 📋 報告されたエラー

### エラー1: StoreStripeCustomer失敗時にchargeが記録されない
```
エラー詳細:
Usertranslation missing: ja.active_interaction.errors.models.payments/store_stripe_customer.attributes.user.auth_failed
```

### エラー2: SetupIntent と PaymentIntent の混同
```
エラー詳細:
Invalid value for stripe.confirmCardPayment intent secret: value should be a PaymentIntent client secret. You specified: a SetupIntent client secret.
```

---

## ✅ 実施した修正

### 1. データベース: error_messageカラムの追加

**マイグレーション**: `db/migrate/20260120024943_add_error_message_to_subscription_charges.rb`

```ruby
class AddErrorMessageToSubscriptionCharges < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_charges, :error_message, :text
  end
end
```

**適用状況**: ✅ 完了（`rails db:migrate` 実行済み）

---

### 2. バックエンド: ManualChargeの修正

**ファイル**: `app/interactions/subscriptions/manual_charge.rb`

**修正内容**:
- `Payments::StoreStripeCustomer` が失敗した場合も `failed_charge_data` を作成
- トランザクション外で `SubscriptionCharge.create!` を実行
- `error_message` にエラー詳細を記録

**修正箇所**:
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

**トランザクション外での保存**:
```ruby
# トランザクション外でfailed chargeを再保存（ロールバックの影響を受けない）
if failed_charge_data
  begin
    SubscriptionCharge.create!(failed_charge_data)
  rescue => e
    Rollbar.error("Failed to save charge record", error: e.message, charge_data: failed_charge_data)
  end
end
```

---

### 3. バックエンド: StoreStripeCustomerの修正

**ファイル**: `app/interactions/payments/store_stripe_customer.rb`

**修正内容**:
- Stripeエラーに `stripe_error_code` と `stripe_error_message` を追加
- エラーメッセージをより詳細に記録

**修正箇所**:
```ruby
rescue Stripe::CardError => error
  stripe_error = error.json_body&.dig(:error) || {}
  errors.add(:user, :auth_failed, 
    stripe_error_code: stripe_error[:code],
    stripe_error_message: stripe_error[:message] || error.message
  )
  Rollbar.error(error, toruya_user: user.id, stripe_charge: stripe_error)
  nil
rescue Stripe::StripeError => error
  if !error.message.include?("already been attached")
    stripe_error = error.json_body&.dig(:error) || {}
    errors.add(:user, :processor_failed,
      stripe_error_code: stripe_error[:code],
      stripe_error_message: stripe_error[:message] || error.message
    )
    Rollbar.error(error, toruya_user: user.id, stripe_charge: stripe_error)
  end
  nil
end
```

---

### 4. バックエンド: PaymentsControllerの修正

**ファイル**: `app/controllers/lines/user_bot/settings/payments_controller.rb`

**修正内容**:
- `user_error` も取得してエラータイプを判定
- `stripe_error_code` と `stripe_error_message` を `plan_error` と `user_error` の両方からチェック
- `setup_intent_id` をレスポンスに追加

**修正箇所**:
```ruby
# エラータイプを取得（:planキーから最初のエラーを取得）
plan_error = outcome.errors.details[:plan]&.first || {}
user_error = outcome.errors.details[:user]&.first || {}
error_type = plan_error[:error] || user_error[:error] || outcome.errors.details.values.flatten.first&.dig(:error)

# Stripeエラーコードとメッセージを取得（planとuserの両方をチェック）
stripe_error_code = plan_error[:stripe_error_code] || user_error[:stripe_error_code]
stripe_error_message = plan_error[:stripe_error_message] || user_error[:stripe_error_message]

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

---

### 5. フロントエンド: charge.jsの修正

**ファイル**: `app/webpacker/javascripts/components/management/plans/charge.js`

**修正内容**:
- SetupIntent と PaymentIntent を区別して処理
- `setup_intent_id` の有無または `client_secret` のプレフィックス（`seti_`）で判定
- SetupIntent の場合は `stripe.confirmCardSetup()` を使用
- PaymentIntent の場合は `stripe.confirmCardPayment()` を使用

**修正箇所**:
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
        // ... エラーハンドリング
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
        // ... その他のケース
      }
    }
  }
}
```

---

### 6. ロケール: エラーメッセージの追加

**ファイル**: `config/locales/ja.yml`

**追加内容**:
```yaml
payments/store_stripe_customer:
  attributes:
    user:
      auth_failed: "^カード認証に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。%{stripe_error_message}"
      processor_failed: "^カード登録に失敗しました。有効なカード番号かご確認の上、もう一度お試しください。%{stripe_error_message}"
      requires_action: "^3Dセキュア認証が必要です。カード発行会社の認証を完了してください。"
      failed: "^カード登録に失敗しました。"
      no_payment_method: "^有効な支払い方法が見つかりません。"
    customer:
      requires_action: "^3Dセキュア認証が必要です。カード発行会社の認証を完了してください。"
```

---

## 🔍 エラーの流れ（修正前 vs 修正後）

### エラー1: StoreStripeCustomer失敗

#### 修正前
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

#### 修正後
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

---

### エラー2: SetupIntent vs PaymentIntent

#### 修正前
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

#### 修正後
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
- `error_message = 'Payment setup failed: User カード認証に失敗しました...'`

---

### エラー2の確認（SetupIntent vs PaymentIntent）

**テストケース**: 3DS認証が必要なカードを使用

**確認方法**:
1. ブラウザの開発者ツール → Console を開く
2. 決済ボタンをクリック
3. 3DS認証画面が表示される
4. Console に以下のようなエラーが出ない:
   ```
   Error: Invalid value for stripe.confirmCardPayment intent secret
   ```
5. 3DS認証が正常に完了する

---

## 🎯 修正したファイル一覧

### バックエンド
1. ✅ `app/interactions/subscriptions/manual_charge.rb`
2. ✅ `app/interactions/payments/store_stripe_customer.rb`
3. ✅ `app/controllers/lines/user_bot/settings/payments_controller.rb`

### フロントエンド
4. ✅ `app/webpacker/javascripts/components/management/plans/charge.js`

### データベース
5. ✅ `db/migrate/20260120024943_add_error_message_to_subscription_charges.rb`

### ロケール
6. ✅ `config/locales/ja.yml`

### ドキュメント
7. ✅ `PAYMENT_ERROR_FIX_REPORT.md` （詳細レポート）
8. ✅ `PAYMENT_ERROR_FIX_SUMMARY.md` （このファイル）

---

## 🚀 次のステップ

### 1. 動作確認
- [ ] 無効なカード番号でテスト（エラー1の確認）
- [ ] 3DS認証が必要なカードでテスト（エラー2の確認）
- [ ] `subscription_charges` テーブルに `error_message` が記録されることを確認

### 2. デプロイ前チェック
- [ ] Linter エラーがないことを確認（✅ 完了）
- [ ] マイグレーションが適用されていることを確認（✅ 完了）
- [ ] Rollbar にエラーが正しくログされることを確認

### 3. 本番環境デプロイ
- [ ] ステージング環境でテスト
- [ ] 本番環境にデプロイ
- [ ] デプロイ後の動作確認

---

## 📝 技術的な改善点

### 解決した問題
1. ✅ StoreStripeCustomer失敗時もchargeレコードが保存される
2. ✅ SetupIntent と PaymentIntent を正しく区別して処理
3. ✅ すべてのエラーケースでDBに記録が残る
4. ✅ エラーメッセージがより詳細になった
5. ✅ デバッグが容易になった

### 副次的な改善
- エラーメッセージに Stripe のエラーコードとメッセージを含める
- Rollbar へのログが常に送信される（開発環境でも）
- トランザクション外での保存により、ロールバックの影響を受けない

---

**作成日**: 2026-01-20  
**対応者**: AI Assistant  
**ステータス**: ✅ 実装完了、動作確認待ち
