# frozen_string_literal: true

class AllowNullSocialCustomerIdOnEventParticipants < ActiveRecord::Migration[7.0]
  def change
    change_column_null :event_participants, :social_customer_id, true
  end
end
