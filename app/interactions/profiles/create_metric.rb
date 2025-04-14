# frozen_string_literal: true

module Profiles
  class CreateMetric < ActiveInteraction::Base
    object :user

    def execute
      begin
        worksheet = Google::Drive.spreadsheet(
          google_sheet_id: "1aKZ35SIno9Ia1B2q-m8SLej_rt_MK_SpjYYy0ebE1U0",
          gid: 1331600224
        )
        new_row_number = worksheet.num_rows + 1
        new_row_data = [
          user.id,
          I18n.l(user.created_at.to_date),
          I18n.l(user.subscription.trial_expired_date.to_date),
        ]
        new_row_data.each_with_index do |data, index|
          worksheet[new_row_number, index + 1] = data
        end
        worksheet.save

        worksheet
      rescue => e
        errors.add(:base, "Failed to access Google Sheet: #{e.message}")
        nil
      end
    end
  end
end
