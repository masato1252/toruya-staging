module Shops
  class HolidayWorkingUpdate < ActiveInteraction::Base
    object :shop
    boolean :holiday_working, default: false

    def execute
      unless shop.reload.update(holiday_working: holiday_working)
        errors.merge!(shop.errors)
      end
    end
  end
end
