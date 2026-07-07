# Compat API ステージング切替（feat_newBackend）

レガシー Web（kasaike）のブラウザ JSON API を、toruya-next の compat API に向けるための設定です。

## 概要

| 項目 | 値 |
|------|-----|
| 新 API ベース URL | `https://api.toruya.com` |
| Compat プレフィックス | `/v1/compat` |
| 例 | `/lines/user_bot/.../customers.json` → `https://api.toruya.com/v1/compat/lines/user_bot/.../customers.json` |

HTML 画面・フォーム遷移は従来どおり Heroku Rails が配信します。`fetch` / `axios` による JSON API のみ新 API へルーティングされます。

## Heroku 設定（toruya-staging）

```bash
heroku config:set COMPAT_API_ORIGIN=https://api.toruya.com --app toruya-staging
```

未設定の場合は従来どおり同一オリジン（Rails）へ API を送ります。

## API 側（api.toruya.com）必須設定

クロスオリジン cookie / CSRF のため、API の環境変数にステージング Heroku のオリジンを追加してください。

```bash
CORS_ORIGINS=https://toruya-staging.herokuapp.com,http://localhost:3000
```

## ローカル開発

`.env` に追加（任意）:

```bash
COMPAT_API_ORIGIN=https://api.toruya.com
```

ローカル Rails + リモート compat API で動作確認できます。未設定ならローカル Rails API のままです。

## 実装の仕組み

1. `COMPAT_API_ORIGIN` が設定されているとき、レイアウトに `<meta name="compat-api-origin">` を出力
2. Webpack パック起動時に `installCompatApi()` が `fetch` / `axios` をインターセプト
3. 次のパスプレフィックス配下の JSON リクエストを書き換え:
   - `/lines/`
   - `/surveys/`
   - `/customer_verification/`
   - `/online_services/`（顧客向け JSON）
4. **除外**（Rails のまま）:
   - `/stripe_*`（Stripe ポーリング）
   - `/api/images`（ActiveStorage 画像アップロード）
   - `Accept: text/html` の XHR モーダル読み込み

## 検証手順

1. Heroku にデプロイ後、ブラウザ DevTools → Network で API リクエストの Host が `api.toruya.com` になっていることを確認
2. ヘルスチェック: `curl https://api.toruya.com/v1/compat/health`
3. 主要フロー: ログイン、顧客一覧、予約作成、設定保存、ブロードキャスト等

## 制限事項

- **Worker / 非同期ジョブ** は Vercel 上では動きません。LINE 配信・リマインダー等の完全 parity は worker ホスト別途が必要です。
- LINE Login リダイレクト等の **HTML 認証フロー** は Rails が継続処理します。

## 関連

- toruya-next: `doc/phase1/12-v1-parity-roadmap.md`
- toruya-next: `doc/phase1/18-vercel-staging-deploy.md`
