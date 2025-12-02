# frozen_string_literal: true

class FilteredOutcomeFileUploader < CarrierWave::Uploader::Base
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # マルウェアスキャンを実行（ファイル保存前）
  before :cache, :scan_for_malware

  def extension_whitelist
    %w(pdf)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

  private

  def scan_for_malware(file)
    return unless MalwareScanner.enabled?

    begin
      # CarrierWaveの一時ファイルパスを取得
      file_path = file.is_a?(String) ? file : file.path
      MalwareScanner.scan!(file_path)
    rescue MalwareScanner::VirusDetectedError => e
      Rails.logger.error("[FilteredOutcomeFileUploader] Virus detected: #{e.message}")
      raise CarrierWave::IntegrityError, "ウイルスが検出されました。このファイルはアップロードできません。"
    rescue => e
      Rails.logger.error("[FilteredOutcomeFileUploader] Error scanning file: #{e.message}")
      # フェイルセーフモードでない場合はエラーを発生
      unless ENV['MALWARE_SCAN_FAIL_SAFE'].to_s.downcase == 'true'
        raise CarrierWave::IntegrityError, "ファイルのスキャン中にエラーが発生しました。"
      end
    end
  end
end
