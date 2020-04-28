module Booking
  class VerifyCode < ActiveInteraction::Base
    object :booking_page
    string :uuid
    string :code

    def execute
      booking_page.booking_codes.where(uuid: uuid, code: code).where("created_at > ?", Time.zone.now.advance(minutes: -10)).exists?
    end
  end
end
