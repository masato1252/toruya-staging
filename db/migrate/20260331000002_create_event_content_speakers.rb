# frozen_string_literal: true

class CreateEventContentSpeakers < ActiveRecord::Migration[7.0]
  def change
    create_table :event_content_speakers do |t|
      t.references :event_content, null: false, foreign_key: true
      t.string :name, null: false
      t.string :position_title
      t.text :introduction
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :event_content_speakers, [:event_content_id, :position]
  end
end
