# frozen_string_literal: true

class ChangeSocialUserToSocialCustomerInEvents < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      execute "DROP INDEX IF EXISTS index_event_participants_on_event_id_and_social_user_id"
      rename_column :event_participants, :social_user_id, :social_customer_id
      add_index :event_participants, [:event_id, :social_customer_id], unique: true

      execute "DROP INDEX IF EXISTS idx_evt_content_usages_unique"
      rename_column :event_content_usages, :social_user_id, :social_customer_id
      add_index :event_content_usages, [:event_content_id, :social_customer_id], unique: true, name: "idx_evt_content_usages_unique"

      execute "DROP INDEX IF EXISTS idx_evt_upsell_consults_unique"
      rename_column :event_upsell_consultations, :social_user_id, :social_customer_id
      add_index :event_upsell_consultations, [:event_content_id, :social_customer_id], unique: true, name: "idx_evt_upsell_consults_unique"

      execute "DROP INDEX IF EXISTS idx_evt_monitor_apps_unique"
      rename_column :event_monitor_applications, :social_user_id, :social_customer_id
      add_index :event_monitor_applications, [:event_content_id, :social_customer_id], unique: true, name: "idx_evt_monitor_apps_unique"
    end
  end

  def down
    safety_assured do
      remove_index :event_participants, [:event_id, :social_customer_id]
      rename_column :event_participants, :social_customer_id, :social_user_id
      add_index :event_participants, [:event_id, :social_user_id], unique: true

      remove_index :event_content_usages, name: "idx_evt_content_usages_unique"
      rename_column :event_content_usages, :social_customer_id, :social_user_id
      add_index :event_content_usages, [:event_content_id, :social_user_id], unique: true, name: "idx_evt_content_usages_unique"

      remove_index :event_upsell_consultations, name: "idx_evt_upsell_consults_unique"
      rename_column :event_upsell_consultations, :social_customer_id, :social_user_id
      add_index :event_upsell_consultations, [:event_content_id, :social_user_id], unique: true, name: "idx_evt_upsell_consults_unique"

      remove_index :event_monitor_applications, name: "idx_evt_monitor_apps_unique"
      rename_column :event_monitor_applications, :social_customer_id, :social_user_id
      add_index :event_monitor_applications, [:event_content_id, :social_user_id], unique: true, name: "idx_evt_monitor_apps_unique"
    end
  end
end
