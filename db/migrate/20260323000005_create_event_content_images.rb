# frozen_string_literal: true

class CreateEventContentImages < ActiveRecord::Migration[7.0]
  def change
    create_table :event_content_images do |t|
      t.references :event_content, null: false, foreign_key: true
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :event_content_images, [:event_content_id, :position]
  end
end
