# frozen_string_literal: true

# 元々このタイムスタンプで存在した create_event_line_users マイグレーションは
# 2026-03-31 のリファクタで削除され、後続の 20260324000001_reconcile_event_schema.rb に
# `unless table_exists?` 付きのフォールバック生成として一本化された。
#
# しかし toruya-production など、まだ event 系マイグレーションを一度も適用していない環境では、
# 以下の順序で `event_line_users` 不在のまま FK 参照付きテーブルが作られようとして失敗する:
#   20260323000006_create_event_participants.rb
#   20260323000007_create_event_content_usages.rb
#   20260323000008_create_event_upsell_consultations.rb
#   20260323000009_create_event_monitor_applications.rb
#   20260325000001_create_event_activity_logs.rb
#
# それらの FK 参照より前に `event_line_users` を必ず存在させるため、本マイグレーションを
# 元のタイムスタンプ (20260323000005) で復活させる。
# - 既に schema_migrations に 20260323000005 が記録されている環境(dev/staging)では Rails が自動的にスキップする。
# - 20260324000001 が先に走ってテーブルを作成済みの環境では `unless table_exists?` で no-op になる。
class CreateEventLineUsers < ActiveRecord::Migration[7.0]
  def up
    return if table_exists?(:event_line_users)

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

  def down
    drop_table :event_line_users if table_exists?(:event_line_users)
  end
end
