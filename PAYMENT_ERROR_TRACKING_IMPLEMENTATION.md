# 決済エラー追跡機能の実装完了レポート

## 実装内容

### 1. データベース変更 ✅

**マイグレーションファイル作成**: `db/migrate/20260120024943_add_error_message_to_subscription_charges.rb`

```ruby
class AddErrorMessageToSubscriptionCharges < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_charges, :error_message, :text
  end
end
```

**実行方法**:
```bash
# マイグレーション実行
bin/rails db:migrate

# 本番環境
heroku run rails db:migrate -a your-app-name
```

---

### 2. バックエンド変更 ✅

#### 2.1 `app/interactions/subscriptions/charge.rb`

**変更内容**:
- エラー時もfailed状態でchargeレコードを保存
- `error_message`カラムに詳細なエラー情報を記録
- Rollbarへの記録を環境に関係なく実行

**主な修正箇所**:

1. **PaymentIntent が nil の場合**:
```ruby
if payment_intent.nil?
  charge.error_message = "Failed to create payment intent: #{errors.full_messages.join(', ')}"
  charge.auth_failed!
  charge.save!
  errors.add(:plan, :no_payment_method)
  Rollbar.error("Payment intent creation failed", user_id: user.id, errors: errors.full_messages)
  return charge
end
```

2. **canceled 状態の場合**:
```ruby
when "canceled"
  charge.stripe_charge_details = payment_intent.as_json
  charge.error_message = "Payment canceled: #{payment_intent.cancellation_reason}"
  charge.auth_failed!
  charge.save!
  errors.add(:plan, :canceled, client_secret: payment_intent.client_secret)
```

3. **Stripe::CardError の場合**:
```ruby
rescue Stripe::CardError => error
  stripe_error = error.json_body&.dig(:error) || {}
  error_message = stripe_error[:message] || error.message
  
  charge.stripe_charge_details = stripe_error
  charge.error_message = "Card error: #{error_message} (code: #{stripe_error[:code]})"
  charge.auth_failed!
  charge.save!
  
  Rollbar.error(error, user_id: user.id, stripe_charge: stripe_error)
```

4. **Stripe::StripeError の場合**:
```ruby
rescue Stripe::StripeError => error
  stripe_error = error.json_body&.dig(:error) || {}
  error_message = stripe_error[:message] || error.message
  
  charge.stripe_charge_details = stripe_error
  charge.error_message = "Stripe error: #{error_message} (code: #{stripe_error[:code]})"
  charge.processor_failed!
  charge.save!
  
  Rollbar.error(error, user_id: user.id, stripe_charge: stripe_error)
```

5. **その他のエラー**:
```ruby
rescue => e
  charge.error_message = "Unexpected error: #{e.class} - #{e.message}"
  charge.auth_failed!
  charge.save!
  
  Rollbar.error(e, user_id: user.id, charge_id: charge.id)
```

---

#### 2.2 `app/interactions/subscriptions/manual_charge.rb`

**変更内容**:
- トランザクションロールバック時、chargeレコードが消えないよう対応
- エラー時にchargeデータを保持し、トランザクション外で再保存

**主な修正箇所**:

```ruby
def execute
  user = subscription.user
  failed_charge_data = nil  # エラー時のcharge情報を保持

  ActiveRecord::Base.transaction do
    # ... 既存の処理 ...
    
    if charge_outcome.valid?
      # 成功時の処理
    else
      # 決済失敗時、chargeの情報を保持（トランザクション外で再保存するため）
      charge = charge_outcome.result
      if charge
        failed_charge_data = {
          user_id: user.id,
          plan_id: plan.id,
          rank: charging_rank,
          amount_cents: charge_amount.cents,
          amount_currency: charge_amount.currency.iso_code,
          charge_date: charge.charge_date,
          manual: true,
          order_id: charge.order_id,
          state: charge.state,
          stripe_charge_details: charge.stripe_charge_details,
          error_message: charge.error_message
        }
      end
      
      errors.merge!(charge_outcome.errors)
      raise ActiveRecord::Rollback
    end
  end
  
  # トランザクション外でfailed chargeを再保存
  if failed_charge_data
    begin
      SubscriptionCharge.create!(failed_charge_data)
    rescue => e
      Rollbar.error("Failed to save charge record", error: e.message, charge_data: failed_charge_data)
    end
  end
end
```

---

### 3. フロントエンド変更 ✅

#### 3.1 `app/webpacker/javascripts/components/management/plans/charge.js`

**変更内容**:
- 具体的なエラーメッセージを表示
- Stripeエラーコードを表示
- デバッグ情報の出力

**主な修正箇所**:

1. **422エラー時の詳細表示**:
```javascript
// client_secretがない場合、詳細なエラーメッセージを表示
let errorMessage = err.stripe_error_message || err.message || "決済に失敗しました。";

// Stripeエラーコードがあれば追加
if (err.stripe_error_code) {
  errorMessage += `\n\nエラーコード: ${err.stripe_error_code}`;
}

// エラータイプがあれば追加（デバッグ用）
if (err.error_type) {
  errorMessage += `\nエラータイプ: ${err.error_type}`;
}
```

2. **その他のエラー時**:
```javascript
catch (err) {
  this.toggleProcessing()
  
  // エラーメッセージを取得（詳細情報を含む）
  let errorMessage = err.message || 
    (typeof err === 'string' ? err : "決済に失敗しました。");
  
  // Stripeエラーの詳細情報を追加
  if (err.code) {
    errorMessage += `\n\nエラーコード: ${err.code}`;
  }
  if (err.decline_code) {
    errorMessage += `\n拒否コード: ${err.decline_code}`;
  }
  
  // デバッグ情報（開発環境用）
  if (process.env.NODE_ENV === 'development' && err.type) {
    errorMessage += `\n\nエラータイプ: ${err.type}`;
  }
  
  console.error('Payment error details:', err);
  
  this.setState({ errorMessage });
  $("#charge-failed-modal").data('error-message', errorMessage).modal("show");
}
```

---

#### 3.2 `app/webpacker/javascripts/components/management/plans/charge_failed.js`

**変更内容**:
- エラーメッセージの詳細表示
- 複数行対応（改行・エラーコードなど）
- 見やすいUI

**主な修正箇所**:

```javascript
<div className="modal-body">
  {errorMessage ? (
    <>
      <div style={{ color: '#9e2146', marginBottom: '15px', fontWeight: 'bold', padding: '10px', backgroundColor: '#fff5f5', borderRadius: '4px' }}>
        決済に失敗しました
      </div>
      <div style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word', marginBottom: '15px', padding: '10px', backgroundColor: '#f9f9f9', borderRadius: '4px', fontSize: '14px' }}>
        <strong>エラー詳細:</strong><br/>
        {errorMessage}
      </div>
      <div style={{ fontSize: '13px', color: '#666' }}>
        カード情報をご確認の上、もう一度お試しください。問題が解決しない場合は、カード会社またはサポートにお問い合わせください。
      </div>
    </>
  ) : (
    <div>
      カード情報に問題があり決済(変更)できませんでした
    </div>
  )}
</div>
```

---

## 4. デプロイ手順

### 4.1 開発環境でのテスト

```bash
# マイグレーション実行
bin/rails db:migrate

# サーバー起動
bin/rails server

# Webpack起動（別ターミナル）
bin/webpack-dev-server
```

### 4.2 本番環境へのデプロイ

```bash
# Gitにコミット
git add .
git commit -m "Add error tracking for payment failures with detailed error messages"

# Herokuにデプロイ
git push heroku main

# マイグレーション実行
heroku run rails db:migrate -a your-app-name

# ログ確認
heroku logs --tail -a your-app-name
```

---

## 5. 確認項目チェックリスト

### データベース
- [ ] マイグレーションが正常に実行された
- [ ] `subscription_charges`テーブルに`error_message`カラムが追加された
- [ ] 既存レコードには影響がない（NULL許可）

### バックエンド
- [ ] エラー時にchargeレコードが保存される
- [ ] error_messageに詳細情報が記録される
- [ ] Rollbarにエラーが記録される
- [ ] トランザクションロールバック後もchargeが残る

### フロントエンド
- [ ] エラーモーダルに詳細メッセージが表示される
- [ ] Stripeエラーコードが表示される
- [ ] 複数行のエラーメッセージが正しく表示される
- [ ] コンソールにエラー詳細が出力される

---

## 6. テストケース

### 6.1 カードエラー（残高不足など）

**期待される動作**:
1. SubscriptionChargesに`auth_failed`状態で保存
2. error_messageに「Card error: [具体的なエラー]」が記録
3. フロント画面に具体的なエラーメッセージが表示
4. Rollbarにエラーが記録

**確認SQL**:
```sql
SELECT id, user_id, state, error_message, created_at 
FROM subscription_charges 
WHERE state = 'auth_failed' 
ORDER BY created_at DESC 
LIMIT 10;
```

### 6.2 支払い方法が登録されていない

**期待される動作**:
1. SubscriptionChargesに`auth_failed`状態で保存
2. error_messageに「Failed to create payment intent」が記録
3. フロント画面にエラーメッセージが表示
4. Rollbarにエラーが記録

### 6.3 3DS認証が必要

**期待される動作**:
1. SubscriptionChargesに保存される（stateは初期値）
2. フロント画面で3DS認証画面が表示
3. 認証失敗時、error_messageが記録

---

## 7. 調査用クエリ

### 最近の失敗した決済を確認
```sql
SELECT 
  sc.id,
  sc.user_id,
  u.email,
  sc.state,
  sc.error_message,
  sc.stripe_charge_details->>'code' as stripe_error_code,
  sc.created_at
FROM subscription_charges sc
JOIN users u ON u.id = sc.user_id
WHERE sc.state IN ('auth_failed', 'processor_failed')
  AND sc.created_at > NOW() - INTERVAL '7 days'
ORDER BY sc.created_at DESC;
```

### エラーコード別の集計
```sql
SELECT 
  sc.stripe_charge_details->>'code' as error_code,
  sc.state,
  COUNT(*) as count
FROM subscription_charges sc
WHERE sc.state IN ('auth_failed', 'processor_failed')
  AND sc.created_at > NOW() - INTERVAL '30 days'
GROUP BY error_code, sc.state
ORDER BY count DESC;
```

### 特定ユーザーの決済履歴
```sql
SELECT 
  id,
  state,
  amount_cents / 100.0 as amount,
  error_message,
  created_at
FROM subscription_charges
WHERE user_id = :user_id
ORDER BY created_at DESC
LIMIT 20;
```

---

## 8. トラブルシューティング

### エラーメッセージが表示されない

**原因**: 
- キャッシュの問題
- JavaScriptのコンパイルエラー

**対処**:
```bash
# アセットのクリア
bin/rails assets:clobber

# Webpackの再起動
bin/webpack-dev-server
```

### chargeレコードが保存されない

**原因**:
- マイグレーション未実行
- トランザクションの問題

**対処**:
```bash
# マイグレーション状態確認
bin/rails db:migrate:status

# マイグレーション実行
bin/rails db:migrate
```

### Rollbarにエラーが記録されない

**原因**:
- Rollbarの設定問題
- 環境変数の問題

**対処**:
```bash
# Rollbar設定確認
heroku config:get ROLLBAR_ACCESS_TOKEN -a your-app-name

# ログで確認
heroku logs --tail -a your-app-name | grep Rollbar
```

---

## 9. 今後の改善提案

1. **エラーメッセージの国際化**: i18nで多言語対応
2. **エラー統計ダッシュボード**: Adminパネルにエラー統計を表示
3. **自動リトライ**: 一時的なエラーの場合、自動リトライ
4. **ユーザー通知**: エラー時にメール通知
5. **エラーパターンの分析**: よくあるエラーの自動検出と対応

---

**実装完了日**: 2026-01-20  
**実装者**: AI Assistant  
**レビュー**: 未実施（ユーザー確認待ち）
