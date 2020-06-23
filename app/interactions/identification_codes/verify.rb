class IdentificationCodes::Verify < ActiveInteraction::Base
  VALID_TIME_PERIOD = 10

  string :uuid
  string :code, default: nil

  def execute
    identification_code = BookingCode.where(uuid: uuid, code: code).where("created_at > ?", Time.zone.now.advance(minutes: -VALID_TIME_PERIOD)).first
    identification_code.touch if identification_code
    identification_code
  end
end
