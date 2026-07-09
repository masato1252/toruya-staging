# frozen_string_literal: true

class CreateDataPlaneMigrations < ActiveRecord::Migration[7.0]
  def change
    create_table :data_plane_migrations do |t|
      t.bigint :user_id, null: false
      t.datetime :migrated_at, null: false
      t.string :status, null: false, default: "completed"
      t.string :source, null: false, default: "job"
      t.jsonb :metadata, null: false, default: {}
      t.datetime :rolled_back_at

      t.timestamps
    end

    add_index :data_plane_migrations, :user_id, unique: true
    add_index :data_plane_migrations, :migrated_at
    add_index :data_plane_migrations, :rolled_back_at
  end
end
