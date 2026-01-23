class SocialMessages::CreateEmail < ActiveInteraction::Base
  object :customer
  string :email
  string :message
  string :subject
  object :broadcast, default: nil
  object :reservation, default: nil  # 予約関連の通知の場合に渡される

  def execute
    Rails.logger.info "[CreateEmail] ===== メール送信開始 ====="
    Rails.logger.info "[CreateEmail] customer_id: #{customer.id}, email: #{email}"
    Rails.logger.info "[CreateEmail] reservation: #{reservation.present? ? "ID=#{reservation.id}" : 'nil'}"
    Rails.logger.info "[CreateEmail] subject: #{subject}"
    
    # メッセージに予約関連のLINE通知リクエスト案内を追加
    text_message = append_line_notice_request_info(message, format: :text)
    
    # HTML形式のメッセージは元のメッセージの改行も含めて変換
    html_base_message = message.gsub("\n", "<br>")
    html_message = append_line_notice_request_info(html_base_message, format: :html)

    Rails.logger.info "[CreateEmail] should_show_line_notice_request_info?: #{should_show_line_notice_request_info?}"
    if reservation.present?
      Rails.logger.info "[CreateEmail]   - reservation.present?: true"
      Rails.logger.info "[CreateEmail]   - user plan: #{customer.user.subscription.current_plan&.name}"
      Rails.logger.info "[CreateEmail]   - free_level?: #{customer.user.subscription.current_plan&.free_level?}"
      Rails.logger.info "[CreateEmail]   - line_settings_verified?: #{customer.user.social_account&.line_settings_verified?}"
      Rails.logger.info "[CreateEmail]   - existing LineNoticeRequest: #{LineNoticeRequest.pending.find_by(reservation_id: reservation.id).present?}"
    else
      Rails.logger.info "[CreateEmail]   - reservation: nil (予約に関係ないメール)"
    end
    Rails.logger.info "[CreateEmail] text_message length: #{text_message.length} (original: #{message.length})"
    Rails.logger.info "[CreateEmail] LINE案内追加: #{text_message.length > message.length ? 'YES' : 'NO'}"

    SocialMessage.create!(
      social_account: customer.social_customer&.social_account,
      social_customer: customer.social_customer,
      customer_id: customer.id,
      user_id: customer.user_id,
      raw_content: text_message,
      content_type: "text",
      readed_at: Time.current,
      sent_at: Time.current,
      message_type: "bot",
      channel: SocialMessage.channels[:email],
      broadcast: broadcast
    )

    CustomerMailer.with(
      customer: customer,
      email: email,
      text_message: text_message,
      html_message: html_message,
      subject: subject
    ).custom.deliver_now
  end

  private

  def append_line_notice_request_info(original_message, format:)
    # 予約がない、または無料プランでない、またはLINE連携未完了の場合は追加しない
    return original_message unless should_show_line_notice_request_info?

    # 既にリクエスト済みかどうかを確認
    existing_request = LineNoticeRequest.pending.find_by(reservation_id: reservation.id)

    if existing_request
      # リクエスト済みの場合
      append_pending_request_notice(original_message, format: format)
    else
      # 未リクエストの場合
      append_request_invitation(original_message, format: format)
    end
  end

  def should_show_line_notice_request_info?
    return false unless reservation.present?
    return false unless customer.user.subscription.current_plan.free_level?
    return false unless customer.user.social_account&.line_settings_verified?
    
    true
  end

  def append_request_invitation(original_message, format:)
    request_url = Rails.application.routes.url_helpers.line_notice_requests_url(
      reservation_id: reservation.id,
      host: ENV['APP_HOST'] || 'toruya.com',
      protocol: 'https'
    )

    # すべての文字列をUTF-8に統一
    original_message = original_message.force_encoding('UTF-8')
    request_url = request_url.force_encoding('UTF-8')

    if format == :html
      separator = "<br><br>--------------------<br>"
      notice_text = I18n.t('customer_mailer.line_notice_request.invitation_html', request_url: request_url)
      # original_messageは既にHTMLの改行が適用済み
      [original_message, separator, notice_text].join
    else
      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.invitation_text', request_url: request_url)
      [original_message, separator, notice_text].join
    end
  end

  def append_pending_request_notice(original_message, format:)
    # すべての文字列をUTF-8に統一
    original_message = original_message.force_encoding('UTF-8')
    
    if format == :html
      separator = "<br><br>--------------------<br>"
      notice_text = I18n.t('customer_mailer.line_notice_request.pending_approval_html')
      # original_messageは既にHTMLの改行が適用済み
      [original_message, separator, notice_text].join
    else
      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.pending_approval_text')
      [original_message, separator, notice_text].join
    end
  end
end