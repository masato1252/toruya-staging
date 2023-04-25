# frozen_string_literal: true

class SmsClient
  HARUKO_PHONE = "08036238534".freeze

  def self.send(phone_number, message)
    return if Rails.env.test?
    return if phone_number.blank?

    phone_number = phone_number.gsub(/[^0-9]/, '')

    formatted_phone =
      if Rails.configuration.x.env.staging?
        Phonelib.parse(HARUKO_PHONE, :jp).international(true)
      elsif Phonelib.valid_for_country?(phone_number, 'JP')
        Phonelib.parse(phone_number, :jp).international(true)
      else
        Phonelib.parse(phone_number).international(true)
      end

    Twilio::REST::Client.new.messages.create(
      from: Rails.application.secrets.twilio_from_phone,
      to: formatted_phone,
      body: message
    )
  end
end
