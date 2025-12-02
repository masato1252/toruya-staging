# Heroku APT Buildpack を使用した ClamAV セットアップ

このガイドでは、`heroku-community/apt` buildpack を使用して ClamAV をインストールする方法を説明します。

## 📦 必要なファイル

以下のファイルが既に準備されています：

- ✅ `Aptfile` - インストールするパッケージのリスト
- ✅ `clamav/freshclam.conf` - ウイルス定義更新の設定
- ✅ `clamav/clamd.conf` - ClamAVデーモンの設定
- ✅ `.profile.d/clamav.sh` - Dyno起動時の自動セットアップ
- ✅ `bin/setup_clamav.sh` - 手動セットアップスクリプト（オプション）

## 🚀 Heroku へのデプロイ手順

### ステップ1: Buildpack の追加

```bash
# 1. 現在のbuildpackを確認
heroku buildpacks -a your-app-name

# 2. APT buildpackを先頭に追加
heroku buildpacks:add --index 1 heroku-community/apt -a your-app-name

# 3. 確認（以下のような順序になるはず）
heroku buildpacks -a your-app-name
# 出力:
# 1. heroku-community/apt
# 2. heroku/ruby
```

### ステップ2: 環境変数の設定

```bash
# マルウェアスキャンを有効化
heroku config:set MALWARE_SCAN_ENABLED=true -a your-app-name

# フェイルセーフモードを有効化（推奨）
heroku config:set MALWARE_SCAN_FAIL_SAFE=true -a your-app-name

# 確認
heroku config -a your-app-name | grep MALWARE
```

### ステップ3: デプロイ

```bash
# 変更をコミット
git add .
git commit -m "Add ClamAV via APT buildpack"

# Herokuにデプロイ
git push heroku main
```

### ステップ4: 動作確認

```bash
# ログを確認
heroku logs --tail -a your-app-name

# 以下のようなログが出力されるはず：
# -----> Running ClamAV setup...
# [Clamby] Malware scanning is enabled (Heroku)

# Railsコンソールで確認
heroku run rails console -a your-app-name

# 以下を実行:
MalwareScanner.enabled?
# => true

# ClamAVが利用可能か確認
require 'clamby'
system("which clamscan")
# => /usr/bin/clamscan が表示されればOK
```

## 📊 リソース要件

### メモリ使用量

ClamAVは200-400MBのメモリを使用します。以下のDynoサイズを推奨：

| Dynoタイプ | メモリ | ClamAV対応 | 推奨 |
|-----------|-------|-----------|------|
| Free/Hobby | 512MB | ⚠️ ギリギリ | ❌ |
| Standard-1X | 512MB | ⚠️ ギリギリ | ❌ |
| Standard-2X | 1GB | ✅ 可能 | ✅ 推奨 |
| Performance-M | 2.5GB | ✅ 余裕 | ✅ 最適 |

```bash
# Dynoサイズの確認
heroku ps -a your-app-name

# アップグレード（必要な場合）
heroku ps:scale web=1:standard-2x -a your-app-name
```

### ビルド時間

APT buildpackを使用すると、初回ビルド時にClamAVがインストールされます：

- 初回ビルド: +3-5分
- 2回目以降: キャッシュされるため +30秒程度

## 🔍 トラブルシューティング

### ❌ ClamAV が見つからない

**症状**: `clamscan: command not found`

**解決方法**:
1. `Aptfile` が正しく配置されているか確認
2. buildpackの順序を確認（aptが先頭）
3. デプロイログを確認

```bash
heroku logs --tail -a your-app-name | grep -i apt
```

### ❌ ウイルス定義が更新されない

**症状**: `ERROR: Can't open file or directory`

**原因**: freshclamの設定が不正、またはデータベースディレクトリが存在しない

**解決方法**:

```bash
# Dynoに接続して手動確認
heroku run bash -a your-app-name

# ClamAVがインストールされているか確認
which clamscan
# => /usr/bin/clamscan

# データベースディレクトリを確認
ls -la /tmp/clamav

# 手動でウイルス定義を更新
mkdir -p /tmp/clamav
freshclam --config-file=/tmp/freshclam.conf --datadir=/tmp/clamav
```

### ⚠️ メモリ不足エラー

**症状**: `R14 - Memory quota exceeded`

**解決方法**:

```bash
# より大きなDynoにスケールアップ
heroku ps:scale web=1:standard-2x -a your-app-name

# または、マルウェアスキャンを無効化
heroku config:set MALWARE_SCAN_ENABLED=false -a your-app-name
```

### 🐌 スキャンが遅い

**原因**: 
- ウイルス定義が大きい（200-300MB）
- ディスクI/Oが遅い

**対策**:
1. フェイルセーフモードを有効化
2. 非同期処理を活用（Active Storageは自動的に非同期）
3. タイムアウトを設定

## 📈 パフォーマンス最適化

### 1. ウイルス定義の更新を制御

デフォルトでは、dyno起動時にウイルス定義を更新します。これには時間がかかります。

**オプション**: 更新をスキップして古い定義を使用

`.profile.d/clamav.sh` を編集：

```bash
# ウイルス定義の更新をスキップ
# (freshclam --config-file=/tmp/freshclam.conf --datadir=/tmp/clamav 2>&1 | head -20) &
```

### 2. 非同期スキャン

Active Storageは自動的に非同期でスキャンを実行します（`after_commit`コールバック）。

CarrierWaveの場合、Delayed Jobなどで非同期化を検討してください。

### 3. ファイルサイズ制限

大きなファイルのスキャンには時間がかかります。ファイルサイズを制限：

```ruby
# app/models/your_model.rb
validates :file, size: { less_than: 10.megabytes }
```

## 🔒 セキュリティ設定

### 本番環境の推奨設定

```bash
# マルウェアスキャンを有効化
heroku config:set MALWARE_SCAN_ENABLED=true -a production-app

# フェイルセーフモード（スキャンエラーでもアップロードを許可）
heroku config:set MALWARE_SCAN_FAIL_SAFE=true -a production-app
```

### ステージング環境の推奨設定

```bash
# マルウェアスキャンを有効化してテスト
heroku config:set MALWARE_SCAN_ENABLED=true -a staging-app
heroku config:set MALWARE_SCAN_FAIL_SAFE=true -a staging-app
```

### 開発環境

```bash
# .env ファイル
MALWARE_SCAN_ENABLED=false  # ローカルではスキャンを無効化
```

## 🧪 テスト方法

### EICARテストファイル

```bash
# Heroku Railsコンソールで実行
heroku run rails console -a your-app-name

# EICARテストファイルを作成
File.write('/tmp/eicar.txt', 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*')

# スキャンをテスト
MalwareScanner.scan!('/tmp/eicar.txt')
# => MalwareScanner::VirusDetectedError が発生すればOK

# 安全なファイル
File.write('/tmp/safe.txt', 'Hello, World!')
MalwareScanner.scan!('/tmp/safe.txt')
# => true が返ればOK
```

## 💰 コスト見積もり

### Standard-2X Dyno (推奨)

- **Dyno料金**: $50/月 (1 dyno)
- **追加コスト**: なし（APT buildpackは無料）

### Standard-1X Dyno (非推奨)

- **メモリ不足のリスク**が高いため推奨しません

## 📝 メンテナンス

### ウイルス定義の更新

Dyno再起動時に自動的に更新されます：

```bash
# 手動でDynoを再起動
heroku restart -a your-app-name
```

### ログの監視

```bash
# ClamAV関連のログを確認
heroku logs --tail -a your-app-name | grep -i "clamav\|malware"
```

## ✅ チェックリスト

デプロイ前に確認：

- [ ] `Aptfile` が存在し、内容が正しい
- [ ] `heroku-community/apt` buildpackが追加されている
- [ ] `MALWARE_SCAN_ENABLED=true` が設定されている
- [ ] Dynoサイズが Standard-2X 以上
- [ ] `.profile.d/clamav.sh` が存在し、実行権限がある
- [ ] `clamav/freshclam.conf` と `clamav/clamd.conf` が存在
- [ ] デプロイログにエラーがない
- [ ] EICARテストファイルでテスト済み

## 🎯 結論

この方法は、専用のClamAV buildpackよりも以下の点で優れています：

✅ **シンプル** - APT buildpackは公式でメンテナンスされている  
✅ **柔軟** - 他のAPTパッケージも追加可能  
✅ **安定** - 多くのプロジェクトで使用されている  
✅ **最新** - Ubuntuの公式リポジトリから最新版を取得  

ただし、メモリ使用量が多いため、**Standard-2X以上のDynoが必要**です。
コストを抑えたい場合は、`MALWARE_SCAN_ENABLED=false`でスキャンを無効化してください。

