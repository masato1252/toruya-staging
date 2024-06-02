# frozen_string_literal: true

module BusinessSchedules
  class Update < ActiveInteraction::Base
    object :shop
    string :business_state
    integer :day_of_week
    array :business_schedules, default: [] do
      hash do
        string :start_time
        string :end_time
      end
    end

    def execute
      shop.with_lock do
        shop.business_schedules.for_shop.where(day_of_week: day_of_week).destroy_all

        if business_state == "opened"
          business_schedules.each do |business_schedule|
            shop.business_schedules.for_shop.create!(
              business_state: business_state,
              day_of_week: day_of_week,
              start_time: business_schedule[:start_time],
              end_time: business_schedule[:end_time]
            )
          end
        end
      end
    end
  end
end
