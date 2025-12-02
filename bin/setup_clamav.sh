#!/bin/bash
# ClamAV setup script for Heroku

set -e

echo "===> Setting up ClamAV..."

# 環境変数チェック
if [ "$MALWARE_SCAN_ENABLED" != "true" ]; then
  echo "Malware scanning is disabled. Skipping ClamAV setup."
  exit 0
fi

# データベースディレクトリの作成
mkdir -p /tmp/clamav

# 設定ファイルをコピー
if [ -f "$HOME/clamav/freshclam.conf" ]; then
  cp $HOME/clamav/freshclam.conf /tmp/freshclam.conf
  echo "Copied freshclam.conf"
fi

if [ -f "$HOME/clamav/clamd.conf" ]; then
  cp $HOME/clamav/clamd.conf /tmp/clamd.conf
  echo "Copied clamd.conf"
fi

# ClamAVがインストールされているか確認
if ! command -v clamscan &> /dev/null; then
  echo "WARNING: clamscan not found. ClamAV may not be installed."
  exit 1
fi

# ウイルス定義データベースの更新
echo "===> Updating virus definitions..."
if command -v freshclam &> /dev/null; then
  freshclam --config-file=/tmp/freshclam.conf --datadir=/tmp/clamav || {
    echo "WARNING: Failed to update virus definitions. Using bundled definitions if available."
  }
else
  echo "WARNING: freshclam not found"
fi

# データベースファイルの確認
if [ -f /tmp/clamav/main.cvd ] || [ -f /tmp/clamav/main.cld ]; then
  echo "===> ClamAV database found"
  ls -lh /tmp/clamav/
else
  echo "WARNING: ClamAV database not found. Scanning may not work."
fi

echo "===> ClamAV setup complete"

