# SetupIntent/PaymentIntent混同エラーの完全修正

## 🐛 問題

ユーザー画面に以下のエラーが表示される：
```
Invalid value for stripe.confirmCardPayment intent secret: value should be a PaymentIntent client secret. You specified: a SetupIntent client secret.
```

**原因**: SetupIntentのclient_secretを、PaymentIntent用のメソッド（`confirmCardPayment`）に渡している。

---

## 🔍 根本原因

### 判定ロジックの問題

**修正前のコード**:
```javascript
const isSetupIntent = err.setup_intent_id || err.client_secret.startsWith('seti_');
```

**問題点**:
1. `err.setup_intent_id`がnull/undefinedではなく、空文字列の場合、falsyとして判定される
2. `err.client_secret`が存在しない場合、エラーが発生する可能性

---

## ✅ 完全修正

### 修正1: より厳密な判定

**ファイル**: `app/webpacker/javascripts/components/management/plans/charge.js`

```javascript
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
```

**改善点**:
- `!!`で明示的にbooleanに変換
- `err.client_secret`の存在チェックを追加
- デバッグログで判定結果を確認できるように

---

### 修正2: PaymentIntentブランチでのSetupIntent検出

```javascript
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
```

**改善点**:
- PaymentIntentブランチに入ったにも関わらず、SetupIntentのclient_secretが渡されている場合、エラーを出して処理を中断
- バックエンドのメッセージを表示

---

### 修正3: 各Stripe API呼び出し前のタイプチェック

```javascript
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
```

**改善点**:
- 各caseの前にclient_secretのタイプを再確認
- SetupIntentなのにPaymentIntentのメソッドを呼ぼうとした場合、事前にエラーを出す
- `handleCardAction`はSetupIntentとPaymentIntentの両方で使えるため、チェック不要

---

## 📊 デバッグログの見方

エラーが発生したときに、ブラウザのコンソールに以下のようなログが出力されます：

### 正常なSetupIntentの場合
```
Payment intent detection: {
  setup_intent_id: "seti_xxx",
  payment_intent_id: null,
  client_secret_prefix: "seti_",
  isSetupIntent: true,
  error_type: "requires_action"
}
```

### 正常なPaymentIntentの場合
```
Payment intent detection: {
  setup_intent_id: null,
  payment_intent_id: "pi_xxx",
  client_secret_prefix: "pi_xx",
  isSetupIntent: false,
  error_type: "requires_action"
}
PaymentIntent branch: {
  errorType: "requires_action",
  client_secret_prefix: "pi_xx"
}
```

### 異常な場合（SetupIntentなのにPaymentIntentブランチに入った）
```
Payment intent detection: {
  setup_intent_id: null,
  payment_intent_id: null,
  client_secret_prefix: "seti_",
  isSetupIntent: false,  ← ここがfalseなのが問題
  error_type: "requires_action"
}
PaymentIntent branch: {
  errorType: "requires_action",
  client_secret_prefix: "seti_"
}
ERROR: SetupIntent client_secret in PaymentIntent branch!
```

この場合、バックエンドのメッセージが表示され、生のStripeエラーは出ません。

---

## 🎯 client_secretの形式

### SetupIntent
```
seti_1234567890abcdefg_secret_XXXXXXXX
```
- プレフィックス: `seti_`

### PaymentIntent
```
pi_1234567890abcdefg_secret_XXXXXXXX
```
- プレフィックス: `pi_`

---

## 🚀 デバッグ手順

1. **ブラウザのコンソールを開く** (F12 → Console)
2. **決済を試みる**
3. **コンソールに出力されるログを確認**:
   - `Payment intent detection:` - 判定結果
   - `PaymentIntent branch:` または `SetupIntent branch:` - どのブランチに入ったか
   - `ERROR:` - 異常があった場合

4. **ログをスクショして報告**

---

## ✅ 修正後の動作

### SetupIntentの場合（カード登録）
1. バックエンドが`setup_intent_id`と`client_secret`（`seti_`で始まる）を返す
2. `isSetupIntent = true`と判定
3. `stripe.confirmCardSetup()`を呼ぶ（正しい）
4. エラーが発生した場合、バックエンドのメッセージ（例: 「3Dセキュア認証が必要です...」）を表示

### PaymentIntentの場合（決済）
1. バックエンドが`payment_intent_id`と`client_secret`（`pi_`で始まる）を返す
2. `isSetupIntent = false`と判定
3. `stripe.confirmCardPayment()`または`stripe.handleCardAction()`を呼ぶ（正しい）
4. エラーが発生した場合、バックエンドのメッセージを表示

---

## 📝 コンパイルと確認

1. **JavaScriptをコンパイル**:
   ```bash
   bin/webpack
   ```

2. **ブラウザキャッシュを完全にクリア**:
   - 開発者ツール → Application → Clear storage → Clear site data
   - または、シークレットウィンドウで確認

3. **動作確認**:
   - エラーが発生したときに、コンソールにデバッグログが出ることを確認
   - ユーザーには親切なメッセージ（バックエンドから返されたもの）が表示されることを確認
   - 生のStripeエラーメッセージが表示されないことを確認

---

**作成日**: 2026-01-20  
**対応者**: AI Assistant  
**ステータス**: ✅ 実装完了、コンパイル＆動作確認待ち
