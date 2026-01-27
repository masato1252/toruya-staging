#!/bin/bash
# Heroku dyno startup script for ClamAV
# This file is automatically executed when the dyno starts

if [ "$MALWARE_SCAN_ENABLED" = "true" ]; then
  echo "-----> Running ClamAV setup..."
  
  # データベースディレクトリの作成
  mkdir -p /tmp/clamav
  
  # 設定ファイルをコピー
  if [ -d "$HOME/clamav" ]; then
    cp -r $HOME/clamav/* /tmp/ 2>/dev/null || true
  fi
  
  # ウイルス定義の更新（バックグラウンドで実行）
  if command -v freshclam &> /dev/null; then
    (freshclam --config-file=/tmp/freshclam.conf --datadir=/tmp/clamav 2>&1 | head -20) &
  fi
  
  echo "-----> ClamAV setup initiated"
fi

