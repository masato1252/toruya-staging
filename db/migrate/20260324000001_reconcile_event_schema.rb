# frozen_string_literal: true

class ReconcileEventSchema < ActiveRecord::Migration[7.0]
  def up
    unless table_exists?(:event_line_users)
      create_table :event_line_users do |t|
        t.string :line_user_id, null: false
        t.string :display_name
        t.string :picture_url
        t.string :first_name
        t.string :last_name
        t.string :phone_number
        t.jsonb :business_types, default: [], null: false
        t.integer :business_age
        t.bigint :toruya_user_id
        t.bigint :toruya_social_user_id
        t.datetime :toruya_user_checked_at

        t.timestamps
      end

      add_index :event_line_users, :line_user_id, unique: true
      add_index :event_line_users, :toruya_user_id
      add_index :event_line_users, :toruya_social_user_id
      add_index :event_line_users, :phone_number
    end

    if table_exists?(:event_participants)
      unless column_exists?(:event_participants, :event_line_user_id)
        add_reference :event_participants, :event_line_user, null: true, foreign_key: true
      end
      unless column_exists?(:event_participants, :concern_labels)
        add_column :event_participants, :concern_labels, :jsonb, default: [], null: false
      end
    end

    if table_exists?(:event_content_usages)
      unless column_exists?(:event_content_usages, :event_line_user_id)
        add_reference :event_content_usages, :event_line_user, null: true, foreign_key: true
      end
    end

    if table_exists?(:event_upsell_consultations)
      unless column_exists?(:event_upsell_consultations, :event_line_user_id)
        add_reference :event_upsell_consultations, :event_line_user, null: true, foreign_key: true
      end
    end

    if table_exists?(:event_monitor_applications)
      unless column_exists?(:event_monitor_applications, :event_line_user_id)
        add_reference :event_monitor_applications, :event_line_user, null: true, foreign_key: true
      end
    end
  end

  def down
    remove_reference :event_monitor_applications, :event_line_user, foreign_key: true if column_exists?(:event_monitor_applications, :event_line_user_id)
    remove_reference :event_upsell_consultations, :event_line_user, foreign_key: true if column_exists?(:event_upsell_consultations, :event_line_user_id)
    remove_reference :event_content_usages, :event_line_user, foreign_key: true if column_exists?(:event_content_usages, :event_line_user_id)
    remove_column :event_participants, :concern_labels if column_exists?(:event_participants, :concern_labels)
    remove_reference :event_participants, :event_line_user, foreign_key: true if column_exists?(:event_participants, :event_line_user_id)
    drop_table :event_line_users if table_exists?(:event_line_users)
  end
end
