# frozen_string_literal: true

module Staffs
  class Invite < ActiveInteraction::Base
    object :user
    string :phone_number
    string :level, default: "admin"

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

          shop.menus.each do |menu|
            StaffMenu
              .create_with(priority: 0, max_customers: 1)
              .find_or_create_by!(menu: menu, staff: staff)
          end
        end

        # All the staff be invited was admin currently.
        compose(StaffAccounts::Create, staff: staff, params: { phone_number: phone_number, level: level })
      end
    end
  end
end
