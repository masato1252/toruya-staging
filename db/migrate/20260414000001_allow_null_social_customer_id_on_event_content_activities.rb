# frozen_string_literal: true

class AllowNullSocialCustomerIdOnEventContentActivities < ActiveRecord::Migration[7.0]
  def change
    change_column_null :event_content_usages, :social_customer_id, true
    change_column_null :event_upsell_consultations, :social_customer_id, true
    change_column_null :event_monitor_applications, :social_customer_id, true
  end
end
