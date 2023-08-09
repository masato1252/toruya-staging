# frozen_string_literal: true

module CustomSchedules
  class Update < ActiveInteraction::Base
    object :custom_schedule
    hash :attrs, default: {} do
      string :shop_id, default: nil
      string :start_time_date_part, default: nil
      string :start_time_time_part, default: nil
      string :end_time_date_part, default: nil
      string :end_time_time_part, default: nil
      string :reason, default: nil
      boolean :open, default: false
    end

    def execute
      custom_schedule.update(attrs)
    end
  end
end
