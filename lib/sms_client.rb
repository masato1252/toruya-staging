class SmsClient
  LAKE_PHONE = "886910819086".freeze
  HARUKO_PHONE = "08036238534".freeze

  def self.send(phone_number, message)
    return if Rails.env.test?

    phone_number.gsub!(/[^0-9]/, '')

    # XXX: Japan dependency
    formatted_phone =
      if Rails.env.development?
        Phonelib.parse(LAKE_PHONE).international(true)
      elsif Rails.configuration.x.env.staging?
        Phonelib.parse(HARUKO_PHONE, :jp).international(true)
      else
        Phonelib.parse(phone_number, :jp).international(true)
      end

    Twilio::REST::Client.new.messages.create(
      from: Rails.application.secrets.twilio_from_phone,
      to: formatted_phone,
      body: message
    )
  end
end
