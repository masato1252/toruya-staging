class SocialMessages::CreateEmail < ActiveInteraction::Base
  object :customer
  string :email
  string :message
  string :subject
  object :broadcast, default: nil
  object :reservation, default: nil  # 予約関連の通知の場合に渡される

  def execute
    # メッセージに予約関連のLINE通知リクエスト案内を追加
    text_message = append_line_notice_request_info(message, format: :text)
    html_message = append_line_notice_request_info(message, format: :html)

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

    if format == :html
      separator = "<br><br>--------------------<br>"
      line_break = "<br>"
      notice_text = I18n.t('customer_mailer.line_notice_request.invitation_html',
        request_url: request_url,
        default: "店主の設定により、お知らせがメールにて送信されています。次回以降のお知らせをLINEで受け取りたい方は、以下のリンクよりLINE連携して、店主へリクエストを送信してください。#{line_break}#{line_break}＜LINEでお知らせをリクエスト＞#{line_break}#{request_url}"
      )
      # 既存のメッセージにもHTMLの改行を適用
      html_original = original_message.gsub("\n", "<br>")
      "#{html_original}#{separator}#{notice_text}"
    else
      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.invitation_text',
        request_url: request_url,
        default: "店主の設定により、お知らせがメールにて送信されています。次回以降のお知らせをLINEで受け取りたい方は、以下のリンクよりLINE連携して、店主へリクエストを送信してください。\n\n＜LINEでお知らせをリクエスト＞\n#{request_url}"
      )
      "#{original_message}#{separator}#{notice_text}"
    end
  end

  def append_pending_request_notice(original_message, format:)
    if format == :html
      separator = "<br><br>--------------------<br>"
      notice_text = I18n.t('customer_mailer.line_notice_request.pending_approval_html',
        default: "LINEでお知らせをリクエスト済みですが、店主の承認が得られるまで、お知らせはメールにて送信されます。店主による承認をお待ちください。"
      )
      # 既存のメッセージにもHTMLの改行を適用
      html_original = original_message.gsub("\n", "<br>")
      "#{html_original}#{separator}#{notice_text}"
    else
      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.pending_approval_text',
        default: "LINEでお知らせをリクエスト済みですが、店主の承認が得られるまで、お知らせはメールにて送信されます。店主による承認をお待ちください。"
      )
      "#{original_message}#{separator}#{notice_text}"
    end
  end
end