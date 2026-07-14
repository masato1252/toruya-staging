# Compat API ステージング切替（feat_newBackend）

レガシー Web（kasaike）のブラウザ JSON API を、toruya-next の compat API に向けるための設定です。

## 概要

| 項目 | 値 |
|------|-----|
| 新 API ベース URL | `https://api.toruya.com` |
| Compat プレフィックス | `/v1/compat` |
| 例 | `/lines/user_bot/.../customers.json` → `https://api.toruya.com/v1/compat/lines/user_bot/.../customers.json` |

HTML 画面・フォーム遷移は従来どおり Heroku Rails が配信します。`fetch` / `axios` による JSON API のみ新 API へルーティングされます。

## Heroku 環境変数（toruya-staging）

```bash
# 必須（compat を使う場合）
heroku config:set COMPAT_API_ORIGIN=https://api.toruya.com --app toruya-staging
heroku config:set COMPAT_ADMIN_PROXY_SECRET=<api と共有する secret> --app toruya-staging

# 領域ごとの切替（true の完全一致のみ有効。未設定 / false はレガシー）
heroku config:set COMPAT_ADMIN_ENABLED=true --app toruya-staging
heroku config:set COMPAT_EVENT_ENABLED=true --app toruya-staging
heroku config:set COMPAT_API_READ_ENABLED=true --app toruya-staging
```

## 切替マトリクス

| 対象 | 環境変数 | 追加条件 | 無効時 |
|------|----------|----------|--------|
| Admin チャット | `COMPAT_ADMIN_ENABLED=true` | `COMPAT_API_ORIGIN`, `COMPAT_ADMIN_PROXY_SECRET` | Rails レガシー read/write |
| Admin イベント管理 | 同上 | 同上 | 同上 |
| Admin シナリオ・一斉送信 | 同上 | 同上 | 同上 |
| Admin 資料管理 | 同上 | 同上 | 同上 |
| 公開資料 DL | 同上 | 同上 | Rails レガシー |
| イベント公開画面 | `COMPAT_EVENT_ENABLED=true` | 同上 + イベント owner が `data_plane_migrations` 済み | Rails レガシー SSR |
| イベント参加登録 | 同上 | 同上 | 同上 |
| イベントコンテンツ | 同上 | 同上 | 同上 |
| Owner / 予約 / 顧客 | `COMPAT_API_READ_ENABLED=true` | 同上 + owner が migration 済み | Rails レガシー |

Admin とイベント公開は **独立** に切り替えられます。イベントを end-to-end で compat にするには、通常 **両方** を `true` にします。

## 移行期のイベント出展者判定（LINE 参加登録）

Toruya ユーザーが移行済み・未移行で混在する期間向けの挙動です。

1. LINE ログイン後、Toruya ユーザー ID ごとに `DataPlaneMigration.migrated?` を判定
2. **移行済み** ユーザーの店舗所属 → v1 API が参照
3. **未移行** ユーザーの店舗所属 → Rails AR で解決し、`session[:event_legacy_shop_ids]` に保持
4. v1 への read は Rails が `legacy_shop_ids` を署名付きヘッダで付与
5. イベント本体のデータプレーンは **イベント owner の migration 状態** に従う

`COMPAT_EVENT_ENABLED=false` の場合、上記の v1 連携は行わず、LINE ログイン〜参加登録はすべて Rails レガシーです。

## API 側（api.toruya.com）必須設定

```bash
CORS_ORIGINS=https://toruya-staging.herokuapp.com,http://localhost:3000
COMPAT_ADMIN_PROXY_SECRET=<kasaike と同じ secret>
```

## ローカル開発

`.env` に追加（任意）:

```bash
COMPAT_API_ORIGIN=https://api.toruya.com
COMPAT_ADMIN_ENABLED=true
COMPAT_EVENT_ENABLED=true
COMPAT_ADMIN_PROXY_SECRET=local-dev-secret
```

## 実装の仕組み

1. `COMPAT_API_ORIGIN` 設定時、レイアウトに `<meta name="compat-api-origin">` を出力
2. `COMPAT_ADMIN_ENABLED=true` → `<meta name="compat-api-admin-enabled" content="true">`
3. イベント compat 画面 → `<meta name="compat-api-event-enabled" content="true">`
4. Webpack パック起動時に `installCompatApi()` が `fetch` / `axios` をインターセプト
5. Admin GET は `/admin/compat_read?path=...` 経由（Rails が proxy 署名）
6. Admin write / イベント mutation は Rails thin controller 経由（secret をブラウザに出さない）

## 検証手順

1. Heroku にデプロイ後、Network で Admin / イベント JSON の Host を確認
2. `curl https://api.toruya.com/v1/compat/health`
3. `COMPAT_ADMIN_ENABLED=false` にすると Admin チャット・資料がレガシー AR に戻ること
4. `COMPAT_EVENT_ENABLED=false` にするとイベント公開・参加がレガシー SSR に戻ること

## 制限事項

- **Worker / 非同期ジョブ** は Vercel 上では動きません
- **LINE Login リダイレクト** 等の HTML 認証フローは Rails が継続処理します

## 関連

- toruya-next: `doc/phase1/12-v1-parity-roadmap.md`
- toruya-next: `doc/phase1/18-vercel-staging-deploy.md`
