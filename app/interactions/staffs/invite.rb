# frozen_string_literal: true

module Staffs
  class Invite < ActiveInteraction::Base
    object :user
    string :phone_number
    string :level, default: "admin"

    def execute
      user.with_lock do
        staff = user.staffs.new
        staff.save
        # All the staff be invited was admin currently.
        compose(StaffAccounts::Create, staff: staff, params: { phone_number: phone_number, level: level })
      end
    end
  end
end
