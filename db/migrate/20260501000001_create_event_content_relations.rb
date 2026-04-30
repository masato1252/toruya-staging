# frozen_string_literal: true

class CreateEventContentRelations < ActiveRecord::Migration[7.0]
  def change
    create_table :event_content_relations do |t|
      t.references :event_content, null: false, foreign_key: true
      t.bigint :related_event_content_id, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :event_content_relations, :related_event_content_id
    add_index :event_content_relations,
              [:event_content_id, :related_event_content_id],
              unique: true,
              name: "index_event_content_relations_on_pair"
    add_foreign_key :event_content_relations, :event_contents, column: :related_event_content_id
  end
end
