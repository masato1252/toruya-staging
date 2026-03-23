# frozen_string_literal: true

class FixEventForeignKeysToSocialCustomers < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      # Remove old FKs pointing to social_users
      execute <<-SQL
        ALTER TABLE event_participants DROP CONSTRAINT IF EXISTS fk_rails_5b10110db9;
        ALTER TABLE event_content_usages DROP CONSTRAINT IF EXISTS #{fk_name('event_content_usages', 'social_user_id')};
        ALTER TABLE event_upsell_consultations DROP CONSTRAINT IF EXISTS #{fk_name('event_upsell_consultations', 'social_user_id')};
        ALTER TABLE event_monitor_applications DROP CONSTRAINT IF EXISTS #{fk_name('event_monitor_applications', 'social_user_id')};
      SQL

      # Also drop any FK constraints that reference social_customer_id -> social_users
      # (in case rename carried them over with auto-generated names)
      %w[event_participants event_content_usages event_upsell_consultations event_monitor_applications].each do |table|
        fks = foreign_keys(table).select { |fk| fk.column == "social_customer_id" }
        fks.each { |fk| remove_foreign_key table, name: fk.name }
      end

      # Add new FKs pointing to social_customers
      add_foreign_key :event_participants, :social_customers
      add_foreign_key :event_content_usages, :social_customers
      add_foreign_key :event_upsell_consultations, :social_customers
      add_foreign_key :event_monitor_applications, :social_customers
    end
  end

  def down
    safety_assured do
      remove_foreign_key :event_participants, :social_customers
      remove_foreign_key :event_content_usages, :social_customers
      remove_foreign_key :event_upsell_consultations, :social_customers
      remove_foreign_key :event_monitor_applications, :social_customers

      add_foreign_key :event_participants, :social_users, column: :social_customer_id
      add_foreign_key :event_content_usages, :social_users, column: :social_customer_id
      add_foreign_key :event_upsell_consultations, :social_users, column: :social_customer_id
      add_foreign_key :event_monitor_applications, :social_users, column: :social_customer_id
    end
  end

  private

  def fk_name(table, column)
    fks = foreign_keys(table).select { |fk| fk.column == column }
    fks.first&.name || "nonexistent_fk"
  end

  def foreign_keys(table)
    ActiveRecord::Base.connection.foreign_keys(table)
  end
end
