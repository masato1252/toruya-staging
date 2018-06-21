module Staffs
  class Create < ActiveInteraction::Base
    object :user

    hash :attrs, default: nil do
      string :first_name, default: nil
      string :last_name, default: nil
      string :phonetic_first_name, default: nil
      string :phonetic_last_name, default: nil
      boolean :staff_holiday_permission, default: false
      array :shop_ids, default: nil
    end

    def execute
      staff = user.staffs.new(attrs || {})

      if staff.save
        staff
      else
        errors.merge!(staff.errors)
      end
    end
  end
end
