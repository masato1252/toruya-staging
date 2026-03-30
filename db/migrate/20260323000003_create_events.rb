# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.datetime :start_at
      t.datetime :end_at
      t.boolean :published, default: false, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :events, :slug, unique: true
    add_index :events, :deleted_at
    add_index :events, :published
  end
end
