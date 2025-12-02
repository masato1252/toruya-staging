# frozen_string_literal: true

# Clamby (ClamAV) Configuration
# ClamAVを使用してファイルのマルウェアスキャンを行うための設定

# 環境変数を直接チェック（MalwareScannerクラスがまだロードされていない可能性があるため）
if ENV['MALWARE_SCAN_ENABLED'].to_s.downcase == 'true'
  Clamby.configure({
    # ClamAVのチェック方法
    # :clamscan - コマンドラインツールを使用（デフォルト）
    # :daemonize - ClamAVデーモンを使用（高速）
    check: :clamscan,
    
    # ClamAVデーモンのホストとポート（daemonize使用時）
    # daemonize_host: 'localhost',
    # daemonize_port: 3310,
    
    # clamscanコマンドのパス（必要に応じて変更）
    # path: '/usr/bin/clamscan',
    
    # エラー時の動作
    # false: エラーを例外として発生させる
    # true: エラーを無視する（フェイルセーフモード）
    error_clamscan_missing: false,
    error_clamscan_client_error: false,
    error_file_missing: false,
    error_file_virus: false
  })

  Rails.logger.info("[Clamby] Malware scanning is enabled")
  
  # ClamAVの可用性をチェック（起動時のチェックはスキップ）
  # 実際のスキャン時にClamAVの可用性が確認されます
else
  Rails.logger.info("[Clamby] Malware scanning is disabled")
end

