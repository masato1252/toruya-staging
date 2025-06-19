# frozen_string_literal: true

module Staffs
  class Invite < ActiveInteraction::Base
    object :user
    string :phone_number_or_email
    string :level, default: "admin"
    boolean :consultant, default: false

    def execute
      user.with_lock do
        staff = user.staffs.new(
          shop_ids: Shop.where(user: user).active.pluck(:id)
        )
        staff.save

        user.shops.each do |shop|
          if staff && !staff.business_schedules.where(shop: shop).exists?
            BusinessSchedules::Create.run!(
              shop: shop,
              staff: staff,
              attrs: {
                full_time: true
              }
            )
          end
        end

        if phone_number_or_email.include?("@")
          email = phone_number_or_email
          phone_number = nil
        else
          email = nil
          phone_number = phone_number_or_email
        end

        # All the staff be invited was admin currently.
        compose(StaffAccounts::Create, staff: staff, params: { phone_number: phone_number, email: email, level: level }, consultant: consultant)

        staff
      end
    end
  end
end
