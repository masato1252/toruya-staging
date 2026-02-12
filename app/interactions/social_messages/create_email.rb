require "message_encryptor"

class SocialMessages::CreateEmail < ActiveInteraction::Base
  object :customer
  string :email
  string :message
  string :subject
  object :broadcast, default: nil
  object :reservation, default: nil  # 予約関連の通知の場合に渡される
  object :custom_message, default: nil  # メッセージの種類を識別するためのCustomMessage

  def execute
    Rails.logger.info "[CreateEmail] ===== メール送信開始 ====="
    Rails.logger.info "[CreateEmail] customer_id: #{customer.id}, email: #{email}"
    Rails.logger.info "[CreateEmail] reservation: #{reservation.present? ? "ID=#{reservation.id}" : 'nil'}"
    Rails.logger.info "[CreateEmail] custom_message: #{custom_message.present? ? "ID=#{custom_message.id}, scenario=#{custom_message.scenario}" : 'nil'}"
    Rails.logger.info "[CreateEmail] subject: #{subject}"
    
    # メッセージに予約関連のLINE通知リクエスト案内を追加
    text_message = append_line_notice_request_info(message, format: :text)
    
    # HTML形式のメッセージは元のメッセージの改行も含めて変換
    html_base_message = message.gsub("\n", "<br>")
    html_message = append_line_notice_request_info(html_base_message, format: :html)

    Rails.logger.info "[CreateEmail] text_message length: #{text_message.length} (original: #{message.length})"
    Rails.logger.info "[CreateEmail] LINE案内追加: #{text_message.length > message.length ? 'YES' : 'NO'}"

    social_message = SocialMessage.create!(
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
      broadcast: broadcast,
      reservation: reservation,
      custom_message_id: custom_message&.id  # CustomMessage IDを保存
    )
    
    Rails.logger.info "[CreateEmail] ✅ SocialMessage作成成功: ID=#{social_message.id}, reservation_id=#{social_message.reservation_id}, custom_message_id=#{social_message.custom_message_id}"

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
    # 予約がない、またはLINE連携未完了の場合は追加しない
    return original_message unless reservation.present?
    return original_message unless customer.user.social_account&.line_settings_verified?

    # マインドマップに基づく条件分岐
    # 1. リクエスト文（通常）：無料プラン（試用期間外）
    # 2. 連携のススメ：顧客LINE連携なし + (有料プラン or 試用期間中)
    
    if should_show_line_request_notice?
      # 最後の通知の場合はLINE通知リクエスト案内を追加しない
      unless reservation.has_future_notifications_for?(customer)
        Rails.logger.info "[CreateEmail] LINE通知リクエスト案内スキップ: 最後の通知のため (reservation_id: #{reservation.id})"
        return original_message
      end

      # 既にリクエスト済みかどうかを確認
      existing_request = LineNoticeRequest.pending.find_by(reservation_id: reservation.id)

      if existing_request
        append_pending_request_notice(original_message, format: format)
      else
        append_request_invitation(original_message, format: format)
      end
    elsif should_show_line_recommendation?
      append_line_recommendation(original_message, format: format)
    else
      original_message
    end
  end

  def should_show_line_request_notice?
    # 無料プラン（試用期間外）の場合のみ
    # ※顧客LINE連携の有無は関係なし
    customer.user.subscription.in_free_plan? && !customer.user.trial_member?
  end

  def should_show_line_recommendation?
    # 顧客LINE連携なし + (有料プラン or 試用期間中)
    customer.social_customer.nil? && (!customer.user.subscription.in_free_plan? || customer.user.trial_member?)
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
      notice_text = I18n.t('customer_mailer.line_notice_request.email.invitation_html', request_url: request_url)
      # original_messageは既にHTMLの改行が適用済み
      [original_message, separator, notice_text].join
    else
      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.email.invitation_text', request_url: request_url)
      [original_message, separator, notice_text].join
    end
  end

  def append_pending_request_notice(original_message, format:)
    # すべての文字列をUTF-8に統一
    original_message = original_message.force_encoding('UTF-8')
    
    if format == :html
      separator = "<br><br>--------------------<br>"
      notice_text = I18n.t('customer_mailer.line_notice_request.email.pending_approval_html')
      # original_messageは既にHTMLの改行が適用済み
      [original_message, separator, notice_text].join
    else
      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.email.pending_approval_text')
      [original_message, separator, notice_text].join
    end
  end

  def append_line_recommendation(original_message, format:)
    line_connect_url = build_line_connect_url
    return original_message unless line_connect_url

    # すべての文字列をUTF-8に統一
    original_message = original_message.force_encoding('UTF-8')
    line_connect_url = line_connect_url.force_encoding('UTF-8')

    if format == :html
      separator = "<br><br>--------------------<br>"
      notice_text = I18n.t('customer_mailer.line_notice_request.line_recommendation_html', line_connect_url: line_connect_url)
      [original_message, separator, notice_text].join
    else
      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.line_recommendation_text', line_connect_url: line_connect_url)
      [original_message, separator, notice_text].join
    end
  end

  def build_line_connect_url
    social_account = customer.user.social_account
    return nil unless social_account&.is_login_available?

    encrypted_id = MessageEncryptor.encrypt(social_account.id)
    # LINE連携後のリダイレクト先（予約詳細ページ）
    redirect_url = Rails.application.routes.url_helpers.shop_reservation_url(
      customer.user.shop, reservation,
      host: ENV['APP_HOST'] || 'toruya.com',
      protocol: 'https'
    )

    # メール/SMS内のリンクはGETでアクセスされるため、
    # OmniAuthのPOST要件を満たす中継ページ経由でLINE連携を開始する
    Rails.application.routes.url_helpers.line_connect_url(
      host: ENV['APP_HOST'] || 'toruya.com',
      protocol: 'https',
      oauth_social_account_id: encrypted_id,
      oauth_redirect_to_url: redirect_url,
      customer_id: customer.id,
      prompt: 'consent',
      bot_prompt: 'aggressive'
    )
  end
end