# LINE通知リクエスト機能 - ユーザー側実装

## 概要
無料プランの店舗の予約に対して、顧客がLINE通知を希望する場合にリクエストを送信できる機能です。

## 実装内容

### 1. コントローラー
- **ファイル**: `app/controllers/line_notice_requests_controller.rb`
- **アクション**:
  - `new`: リクエスト説明画面（LINE連携ボタン表示）
  - `callback`: LINE OAuth後のコールバック処理、リクエスト作成
  - `success`: リクエスト完了画面

### 2. インタラクション
- **ファイル**: `app/interactions/line_notice_requests/create.rb`
- **処理内容**:
  - 予約と顧客の関連確認
  - 店舗が無料プランか確認
  - 既存のpendingリクエストがないか確認
  - LineNoticeRequestレコード作成

### 3. ビュー
- **new.html.erb**: リクエスト説明画面
  - 店舗ロゴ・名前表示
  - 予約詳細表示
  - LINE連携ボタン（緑色、LINE公式カラー）
  - 注意事項（初回無料、2回目以降110円など）
  - 既にリクエスト済みの場合は警告表示

- **success.html.erb**: リクエスト完了画面
  - 完了チェックマークアイコン
  - 成功メッセージ
  - 次のステップの説明
  - 予約詳細へのリンク

### 4. ルーティング
```ruby
resources :line_notice_requests, only: [] do
  collection do
    get :new          # /line_notice_requests/new?reservation_id=123
    get :callback     # /line_notice_requests/callback?reservation_id=123&social_user_id=xxx
    get :success      # /line_notice_requests/success?request_id=123
  end
end
```

### 5. 多言語対応
- **日本語**: `config/locales/ja.yml`
- **台湾語**: `config/locales/tw.yml`

## 使用フロー

1. 顧客が予約完了後、メールまたはボタンから`/line_notice_requests/new?reservation_id=123`にアクセス
2. 説明と注意事項を確認
3. 「LINE連携してリクエストする」ボタンをクリック
4. LINE OAuth認証画面へリダイレクト
5. LINE認証完了後、`/line_notice_requests/callback`にリダイレクト
6. LineNoticeRequestレコードが作成される（status: pending）
7. `/line_notice_requests/success`画面へリダイレクト
8. 完了メッセージ表示

## バリデーション
- 予約が存在すること
- 店舗が無料プランであること
- 予約に顧客が関連付けられていること
- SocialCustomerが存在すること
- 既にpendingのリクエストが存在しないこと

## セキュリティ
- CSRF保護有効（callbackアクションのみskip）
- MessageEncryptorでパラメータ暗号化
- Reservation所有者確認

## 次の実装予定
- 店舗側の承認/拒否画面
- 承認時のLINE通知送信処理
- 課金処理（無料トライアル判定、Stripe決済）
- メール通知（承認/拒否時）

