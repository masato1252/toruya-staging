# frozen_string_literal: true

class IdentificationCodes::Verify < ActiveInteraction::Base
  VALID_TIME_PERIOD = 48

  object :user, default: nil
  string :locale, default: nil
  string :uuid
  string :code, default: nil

  def execute
    I18n.with_locale(user&.locale || locale) do
      identification_code = BookingCode.where(uuid: uuid, code: code).where("created_at > ?", Time.zone.now.advance(hours: -VALID_TIME_PERIOD)).first
      if identification_code
        identification_code.touch
      else
        errors.add(:base, I18n.t("booking_page.message.booking_code_failed_message"))
      end
      identification_code
    end
  end
end
