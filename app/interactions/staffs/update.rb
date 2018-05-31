module Staffs
  class Update < ActiveInteraction::Base
    boolean :is_manager, default: false
    object :staff
    boolean :holiday_working, default: false

    hash :attrs do
      string :first_name, default: nil
      string :last_name, default: nil
      string :phonetic_first_name, default: nil
      string :phonetic_last_name, default: nil
      boolean :staff_holiday_permission, default: false
      array :shop_ids, default: nil
    end

    def execute
      previous_shop_ids = staff.shop_ids

      attrs_allow_to_change = if staff.staff_account.try(:owner?) || !is_manager
                                attrs.slice(:first_name, :last_name, :phonetic_first_name, :phonetic_last_name)
                              else
                                attrs
                              end

      if staff.update(attrs_allow_to_change)
        # clean business_schedules, custom_schedules
        (previous_shop_ids - staff.shop_ids).each do |shop_id|
          staff.business_schedules.where(shop_id: shop_id).destroy_all
          staff.custom_schedules.where(shop_id: shop_id).destroy_all
        end
      else
        errors.merge!(staff.errors)
      end
    end
  end
end
