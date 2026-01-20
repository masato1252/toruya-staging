# Stripeエラーメッセージの完全修正

## 🐛 問題

ユーザー側に以下のような生の技術的なエラーメッセージが表示されていた：
```
Invalid value for stripe.confirmCardPayment intent secret: value should be a PaymentIntent client secret. You specified: a SetupIntent client secret.
```

これは、Stripe JavaScript SDKを直接呼び出している箇所でエラーが発生し、そのエラーメッセージがそのままユーザーに表示されていた。

---

## 🔍 根本原因

### 1. SetupIntent処理でのエラー
```javascript
// 修正前
try {
  result = await stripe.confirmCardSetup(err.client_secret, {
    payment_method: paymentMethodId
  });
} catch (stripeError) {
  const userMessage = stripeError.message;  // ← 生のStripeエラー
  throw new Error(userMessage);
}
```

### 2. PaymentIntent処理でのエラー
```javascript
// 修正前
result = await stripe.confirmCardPayment(err.client_secret, {
  payment_method: paymentMethodId
});
// エラーが発生すると、生のStripeエラーがthrowされる
```

### 3. result.errorの処理
```javascript
// 修正前
if (result.error) {
  throw new Error(result.error.message);  // ← 生のStripeエラー
}
```

---

## ✅ 修正内容

### 1. SetupIntent処理の完全修正

**ファイル**: `app/webpacker/javascripts/components/management/plans/charge.js`

**修正後**:
```javascript
if (isSetupIntent) {
  // SetupIntent の場合（カード登録時）
  try {
    result = await stripe.confirmCardSetup(err.client_secret, {
      payment_method: paymentMethodId
    });
  } catch (stripeError) {
    // Stripe APIエラーをユーザーフレンドリーなメッセージに変換
    console.error('Stripe confirmCardSetup error:', stripeError);
    throw new Error("カード登録の処理中にエラーが発生しました。もう一度お試しいただくか、別のカードをご利用ください。");
  }
  
  if (result.error) {
    console.error('Stripe confirmCardSetup result error:', result.error);
    throw new Error("カード登録に失敗しました。有効なカード情報かご確認の上、もう一度お試しください。");
  }
  // ... 成功時の処理
}
```

**ポイント**:
- `stripeError.message`を使わず、固定のユーザーフレンドリーなメッセージを表示
- `console.error`で詳細なエラーをログに出力（デバッグ用）
- `result.error.message`も使わず、固定メッセージを表示

---

### 2. PaymentIntent処理の完全修正

**修正後**:
```javascript
} else {
  // PaymentIntent の場合（決済時）
  const errorType = err.error_type || err.plan;
  
  // サポートされていないエラータイプの場合は、バックエンドから受け取ったメッセージを使用
  if (!['requires_payment_method', 'requires_source', 'requires_action', 'requires_confirmation'].includes(errorType)) {
    throw new Error(err.message || "決済処理に失敗しました。もう一度お試しください。");
  }
  
  try {
    switch (errorType) {
      case 'requires_payment_method':
      case 'requires_source':
        result = await stripe.confirmCardPayment(err.client_secret, {
          payment_method: paymentMethodId
        });
        break;
      case 'requires_action':
        result = await stripe.handleCardAction(err.client_secret);
        break;
      case 'requires_confirmation':
        result = await stripe.confirmCardPayment(err.client_secret);
        break;
    }
  } catch (stripeError) {
    // Stripe APIエラーをユーザーフレンドリーなメッセージに変換
    console.error('Stripe API error:', stripeError);
    throw new Error("決済の処理中にエラーが発生しました。もう一度お試しいただくか、別のカードをご利用ください。");
  }

  if (result.error) {
    console.error('Stripe confirmCardPayment result error:', result.error);
    throw new Error("決済に失敗しました。有効なカード情報かご確認の上、もう一度お試しください。");
  }
  // ... 成功時の処理
}
```

**ポイント**:
- Stripe API呼び出しを`try-catch`で囲む
- `stripeError.message`を使わず、固定のユーザーフレンドリーなメッセージ
- エラータイプをチェックして、サポートされていないタイプはバックエンドのメッセージを使用
- `result.error.message`も使わず、固定メッセージ

---

### 3. catchブロックの簡潔化

**修正後**:
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

**ポイント**:
- 生のStripeエラーメッセージの変換ロジックを削除
- すでにユーザーフレンドリーなメッセージに変換されているため、そのまま表示

---

## 📊 エラーメッセージの変換例

### 例1: SetupIntent/PaymentIntent の混同エラー

#### 修正前
```
Invalid value for stripe.confirmCardPayment intent secret: value should be a PaymentIntent client secret. You specified: a SetupIntent client secret.
```

#### 修正後
```
決済の処理中にエラーが発生しました。もう一度お試しいただくか、別のカードをご利用ください。
```

---

### 例2: カード認証エラー

#### 修正前（生のStripeエラー）
```
Your card was declined.
```

#### 修正後
```
カード登録に失敗しました。有効なカード情報かご確認の上、もう一度お試しください。
```

---

### 例3: バックエンドからの詳細エラー

バックエンドから `user_message` が返された場合：

#### バックエンドのレスポンス
```json
{
  "message": "3Dセキュア認証が必要です。カード発行会社の認証を完了してください。"
}
```

#### フロントエンドでの表示
```
3Dセキュア認証が必要です。カード発行会社の認証を完了してください。
```

---

## 🎯 デバッグ情報の保持

### console.error による詳細ログ

すべてのStripeエラーは`console.error`でブラウザのコンソールに出力されるため、デバッグは可能：

```javascript
console.error('Stripe confirmCardSetup error:', {
  message: "Invalid value for stripe.confirmCardPayment...",
  type: "invalid_request_error",
  code: "parameter_invalid_empty"
});
```

開発者ツールを開けば、詳細なエラー情報を確認できます。

---

## 🔄 エラーフロー全体像

### 1. バックエンドで発生したエラー

```
エラー発生
  ↓
Interaction: user_message を errors に追加
  ↓
Controller: user_message をレスポンスに含める
  ↓
Frontend: err.message に user_message が含まれる
  ↓
User sees: 親切なメッセージ
```

### 2. フロントエンドのStripe API呼び出しで発生したエラー

```
Stripe API呼び出し
  ↓
エラー発生（例: Invalid value for stripe.confirmCardPayment...）
  ↓
catch (stripeError)
  ↓
console.error でログ出力
  ↓
固定のユーザーフレンドリーなメッセージに変換
  ↓
User sees: "決済の処理中にエラーが発生しました..."
```

---

## 📝 修正したファイル

1. ✅ `app/webpacker/javascripts/components/management/plans/charge.js`
   - SetupIntent処理のエラーハンドリング改善
   - PaymentIntent処理のエラーハンドリング改善
   - result.errorの処理改善
   - catchブロックの簡潔化

---

## 🚀 確認方法

### 1. SetupIntent/PaymentIntent混同エラーのテスト

**シナリオ**: 内部的にSetupIntentとPaymentIntentの判定が誤動作した場合

**期待される表示**:
```
決済の処理中にエラーが発生しました。もう一度お試しいただくか、別のカードをご利用ください。
```

**コンソール（開発者ツール）**:
```
Stripe API error: Error: Invalid value for stripe.confirmCardPayment intent secret...
```

---

### 2. カード拒否エラーのテスト

**テストカード**: `4000 0000 0000 0002`

**期待される表示**:
```
カード登録に失敗しました。有効なカード情報かご確認の上、もう一度お試しください。
```

または（バックエンドから）:
```
支払いに失敗しました。有効なカード番号かご確認の上、もう一度お試しください。
```

---

### 3. 3DS認証が必要な場合

**期待される表示** （バックエンドから）:
```
3Dセキュア認証が必要です。カード発行会社の認証を完了してください。
```

---

## 🎯 まとめ

### 修正前の問題
- Stripe JavaScript SDKの生のエラーメッセージがユーザーに表示されていた
- 技術的すぎて、ユーザーが理解できない

### 修正後の改善
- すべてのStripeエラーをユーザーフレンドリーなメッセージに変換
- 生のエラーは`console.error`でログに出力（デバッグ用）
- ユーザーには次に何をすべきかが明確なメッセージを表示

### デバッグ対応
- `console.error`で詳細なエラー情報を出力
- ブラウザの開発者ツールで確認可能
- DBにも詳細なエラー情報を記録（`error_message`カラム）

---

**作成日**: 2026-01-20  
**対応者**: AI Assistant  
**ステータス**: ✅ 実装完了、動作確認待ち
