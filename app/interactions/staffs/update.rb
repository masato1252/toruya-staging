# frozen_string_literal: true

module Staffs
  class Update < ActiveInteraction::Base
    USER_LEVELS = %w(admin manager staff)
    object :staff

    # user_level: the level of the user who want to change the staff
    # values: admin or manager or staff
    string :user_level

    hash :attrs, default: nil do
      string :first_name, default: nil
      string :last_name, default: nil
      string :phonetic_first_name, default: nil
      string :phonetic_last_name, default: nil
      # examples:
      #   "shop_ids" => ["", "2", "3"],
      #
      #  non-shop cases:
      #   "shop_ids"=>[""], contact_group_attributes => nil
      array :shop_ids, default: nil

      # examples:
      #   "contact_group_ids" => ["", "22", "7"]
      array :contact_group_ids, default: nil
    end

    # staff_account_attributes structure
    # examples:
    #   { "email"=>"foo@email.com" }
    hash :staff_account_attributes, default: nil, strip: false

    # shop_staff_attributes
    # structure:
    # {
    #   $shop_id => {
    #     "level" => "staff" or "manager",
    #     "staff_full_time_permission" => "0" or "1",
    #     "staff_regular_working_day_permission" => "0" or "1",
    #     "staff_temporary_working_day_permission" => "0" or "1"
    #   }
    # }
    #
    # examples:
    # {
    #   "2" => {
    #     "level" => "staff",
    #     "staff_full_time_permission" => "1",
    #     "staff_regular_working_day_permission" => "0",
    #     "staff_temporary_working_day_permission" => "1"
    #   },
    #   "3" => {
    #     "level" => "manager"
    #   }
    # }
    hash :shop_staff_attributes, default: nil, strip: false

    # contact_group_attributes
    # structure:
    # {
    #   $contact_group_id => {
    #     "contact_group_read_permission" => "reservations_only_readable" or "details_readable",
    #   }
    # }
    #
    # examples:
    # {
    #   "22" => {
    #     "contact_group_read_permission" => "reservations_only_readable"
    #   },
    #   "7" => {
    #     "contact_group_read_permission" => "details_readable"
    #   }
    # }
    hash :contact_group_attributes, default: nil, strip: false

    validate :validates_user_level

    def execute
      previous_shop_ids = staff.shop_ids

      attrs_allow_to_change = if staff.staff_account.try(:owner?)
                                attrs.slice(:first_name, :last_name, :phonetic_first_name, :phonetic_last_name)
                              elsif user_level == "admin"
                                attrs || {}
                              elsif user_level == "manager"
                                (attrs || {}).except(:contact_group_ids)
                              else
                                attrs.slice(:first_name, :last_name, :phonetic_first_name, :phonetic_last_name)
                              end

      if staff.update(attrs_allow_to_change)
        # clean up staff working business_schedules and working custom_schedules
        (previous_shop_ids - staff.shop_ids).each do |shop_id|
          staff.business_schedules.where(shop_id: shop_id).destroy_all
          staff.custom_schedules.where(shop_id: shop_id).destroy_all
        end

        if user_level == "admin" || user_level == "manager"
          if staff_account_attributes
            compose(StaffAccounts::Create, staff: staff, params: staff_account_attributes)
          end

          shop_staff_attributes&.each do |shop_id, attrs|
            staff.shop_relations.find_by(shop_id: shop_id).update(attrs.to_h)
          end
        end

        if user_level == "admin"
          contact_group_attributes&.each do |group_id, attrs|
            staff.contact_group_relations.find_by(contact_group_id: group_id).update(attrs.to_h)
          end
        end
      else
        errors.merge!(staff.errors)
      end
    end

    private

    def validates_user_level
      if !USER_LEVELS.include?(user_level)
        errors.add(:user_level, :invalid)
      end
    end
  end
end
