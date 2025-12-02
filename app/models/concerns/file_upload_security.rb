# frozen_string_literal: true

# ファイルアップロードのセキュリティ対策
# マルウェアスキャンが無効な環境でのセキュリティ強化
module FileUploadSecurity
  extend ActiveSupport::Concern

  # 許可するファイルタイプ
  ALLOWED_IMAGE_TYPES = ['image/png', 'image/jpeg', 'image/jpg', 'image/gif', 'image/webp'].freeze
  ALLOWED_DOCUMENT_TYPES = ['application/pdf'].freeze
  ALLOWED_CONTENT_TYPES = (ALLOWED_IMAGE_TYPES + ALLOWED_DOCUMENT_TYPES).freeze

  # 最大ファイルサイズ（10MB）
  MAX_FILE_SIZE = 10.megabytes

  class_methods do
    # Active Storageの添付ファイルにバリデーションを追加
    # @param attachment_name [Symbol] 添付ファイルの名前
    # @param options [Hash] オプション
    #   - content_types: 許可するコンテンツタイプの配列
    #   - max_size: 最大ファイルサイズ（バイト）
    def validate_attachment(attachment_name, options = {})
      allowed_types = options[:content_types] || ALLOWED_CONTENT_TYPES
      max_size = options[:max_size] || MAX_FILE_SIZE

      validate :"validate_#{attachment_name}_content_type"
      validate :"validate_#{attachment_name}_size"

      define_method :"validate_#{attachment_name}_content_type" do
        attachment = send(attachment_name)
        return unless attachment.attached?

        unless allowed_types.include?(attachment.content_type)
          errors.add(attachment_name, :invalid_content_type, 
            message: "は#{allowed_types.join(', ')}のいずれかである必要があります")
        end
      end

      define_method :"validate_#{attachment_name}_size" do
        attachment = send(attachment_name)
        return unless attachment.attached?

        if attachment.byte_size > max_size
          errors.add(attachment_name, :file_too_large,
            message: "は#{max_size / 1.megabyte}MB以下である必要があります")
        end
      end
    end

    # has_many_attachedの場合のバリデーション
    def validate_attachments(attachment_name, options = {})
      allowed_types = options[:content_types] || ALLOWED_CONTENT_TYPES
      max_size = options[:max_size] || MAX_FILE_SIZE
      max_count = options[:max_count] || 10

      validate :"validate_#{attachment_name}_collection"

      define_method :"validate_#{attachment_name}_collection" do
        attachments = send(attachment_name)
        return unless attachments.attached?

        if attachments.count > max_count
          errors.add(attachment_name, :too_many_files,
            message: "は#{max_count}個以下である必要があります")
        end

        attachments.each_with_index do |attachment, index|
          unless allowed_types.include?(attachment.content_type)
            errors.add(attachment_name, :invalid_content_type,
              message: "#{index + 1}番目のファイルのタイプが無効です")
          end

          if attachment.byte_size > max_size
            errors.add(attachment_name, :file_too_large,
              message: "#{index + 1}番目のファイルが大きすぎます（最大#{max_size / 1.megabyte}MB）")
          end
        end
      end
    end
  end
end

