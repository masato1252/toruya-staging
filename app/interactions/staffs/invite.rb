# frozen_string_literal: true

module Staffs
  class Invite < ActiveInteraction::Base
    object :user
    string :phone_number

    def execute
      user.with_lock do
        staff = user.staffs.new
        staff.save
        compose(StaffAccounts::Create, staff: staff, params: { phone_number: phone_number })
      end
    end
  end
end
