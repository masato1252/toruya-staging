# frozen_string_literal: true

# Clamby (ClamAV) Configuration
# ClamAVを使用してファイルのマルウェアスキャンを行うための設定

# 環境変数を直接チェック（MalwareScannerクラスがまだロードされていない可能性があるため）
if ENV['MALWARE_SCAN_ENABLED'].to_s.downcase == 'true'
  config = {
    # ClamAVのチェック方法
    check: :clamscan,
    
    # エラー時の動作（フェイルセーフモードを考慮）
    error_clamscan_missing: false,
    error_clamscan_client_error: false,
    error_file_missing: false,
    error_file_virus: false
  }

  # Heroku環境の場合、カスタムデータベースディレクトリを設定
  if ENV['DYNO'].present?
    config[:daemonize] = false
    config[:fdpass] = false
    # Herokuのaptで自動的にインストールされるパスを使用
    if File.exist?('/usr/bin/clamscan')
      config[:path] = '/usr/bin/clamscan'
    end
    # カスタムデータベースディレクトリ
    if Dir.exist?('/tmp/clamav')
      config[:database] = '/tmp/clamav'
    end
  end

  Clamby.configure(config)

  Rails.logger.info("[Clamby] Malware scanning is enabled (#{ENV['DYNO'] ? 'Heroku' : 'Local'})")
  
  # ClamAVの可用性をチェック（起動時のチェックはスキップ）
  # 実際のスキャン時にClamAVの可用性が確認されます
else
  Rails.logger.info("[Clamby] Malware scanning is disabled")
end

