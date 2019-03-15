module Staffs
  class Update < ActiveInteraction::Base
    object :staff
    string :manager_level, default: nil

    hash :attrs, default: nil do
      string :first_name, default: nil
      string :last_name, default: nil
      string :phonetic_first_name, default: nil
      string :phonetic_last_name, default: nil
      array :shop_ids, default: nil
      array :contact_group_ids, default: nil
    end

    hash :staff_account_attributes, default: nil, strip: false
    hash :shop_staff_attributes, default: nil, strip: false
    hash :contact_group_attributes, default: nil, strip: false

    def execute
      previous_shop_ids = staff.shop_ids

      attrs_allow_to_change = if staff.staff_account.try(:owner?)
                                attrs.slice(:first_name, :last_name, :phonetic_first_name, :phonetic_last_name)
                              elsif manager_level == "admin"
                                attrs || {}
                              elsif manager_level == "manager"
                                (attrs || {}).except(:contact_group_ids)
                              else
                                attrs.slice(:first_name, :last_name, :phonetic_first_name, :phonetic_last_name)
                              end

      if staff.update(attrs_allow_to_change)
        # clean business_schedules, custom_schedules
        (previous_shop_ids - staff.shop_ids).each do |shop_id|
          staff.business_schedules.where(shop_id: shop_id).destroy_all
          staff.custom_schedules.where(shop_id: shop_id).destroy_all
        end

        if staff_account_attributes
          compose(StaffAccounts::Create, staff: staff, owner: staff.user, params: staff_account_attributes)
        end

        shop_staff_attributes&.each do |shop_id, attrs|
          staff.shop_relations.find_by(shop_id: shop_id).update(attrs.to_h)
        end

        contact_group_attributes&.each do |group_id, attrs|
          staff.contact_group_relations.find_by(contact_group_id: group_id).update(attrs.to_h)
        end
      else
        errors.merge!(staff.errors)
      end
    end
  end
end
