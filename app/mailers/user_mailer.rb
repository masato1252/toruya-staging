# frozen_string_literal: true

class UserMailer < ApplicationMailer
  layout :determine_layout

  def custom
    @message_content = params[:message]
    mail(
      to: params[:email],
      subject: params[:subject]
    )
  end

  private

  def determine_layout
    # Check for locale in params or from customer object
    locale = if params[:locale].present?
               params[:locale]
             else
               I18n.locale || I18n.default_locale
             end

    case locale.to_s
    when 'ja'
      'mailer_ja'
    when 'tw'
      'mailer_tw'
    else
      'mailer_en'
    end
  end
end