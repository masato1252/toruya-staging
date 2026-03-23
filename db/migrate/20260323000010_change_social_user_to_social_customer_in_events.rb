# frozen_string_literal: true

class ChangeSocialUserToSocialCustomerInEvents < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # event_participants
      remove_index :event_participants, [:event_id, :social_user_id]
      rename_column :event_participants, :social_user_id, :social_customer_id
      add_index :event_participants, [:event_id, :social_customer_id], unique: true

      # event_content_usages
      remove_index :event_content_usages, name: "idx_evt_content_usages_unique"
      rename_column :event_content_usages, :social_user_id, :social_customer_id
      add_index :event_content_usages, [:event_content_id, :social_customer_id], unique: true, name: "idx_evt_content_usages_unique"

      # event_upsell_consultations
      remove_index :event_upsell_consultations, name: "idx_evt_upsell_consults_unique"
      rename_column :event_upsell_consultations, :social_user_id, :social_customer_id
      add_index :event_upsell_consultations, [:event_content_id, :social_customer_id], unique: true, name: "idx_evt_upsell_consults_unique"

      # event_monitor_applications
      remove_index :event_monitor_applications, name: "idx_evt_monitor_apps_unique"
      rename_column :event_monitor_applications, :social_user_id, :social_customer_id
      add_index :event_monitor_applications, [:event_content_id, :social_customer_id], unique: true, name: "idx_evt_monitor_apps_unique"
    end
  end
end
