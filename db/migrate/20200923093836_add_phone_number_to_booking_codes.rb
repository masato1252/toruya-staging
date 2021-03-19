# frozen_string_literal: true

class AddPhoneNumberToBookingCodes < ActiveRecord::Migration[5.2]
  def change
    add_column :booking_codes, :phone_number, :string
  end
end
