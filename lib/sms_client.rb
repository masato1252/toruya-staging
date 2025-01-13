# frozen_string_literal: true

class SmsClient
  HARUKO_PHONE = "09088158538".freeze

  def self.send(phone_number, message, locale)
    return if Rails.env.test? || Rails.env.development?
    return if phone_number.blank?

    phone_number = phone_number.gsub(/[^0-9]/, '')

    formatted_phone =
      if Rails.configuration.x.env.staging?
        Phonelib.parse(HARUKO_PHONE, "JP").international(true)
      elsif Phonelib.valid?(phone_number)
        Phonelib.parse(phone_number).international(true)
      else
        Phonelib.parse(phone_number, locale_country_code(locale)).international(true)
      end

    Twilio::REST::Client.new.messages.create(
      from: Rails.application.secrets.twilio_from_phone,
      to: formatted_phone,
      body: message
    )
  end

  private

  def locale_country_code(locale)
    case locale
    when "ja", :ja
      "JP"
    else
      locale
    end
  end
end
