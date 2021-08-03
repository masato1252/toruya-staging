# frozen_string_literal: true

module Users
  class UpdateCustomerLatestActivityAt < ActiveInteraction::Base
    object :user

    def execute
      user.update_columns(customer_latest_activity_at: Time.current)
    end
  end
end
