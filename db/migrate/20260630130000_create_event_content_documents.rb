# frozen_string_literal: true

class CreateEventContentDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :event_content_documents do |t|
      t.references :event_content, null: false, foreign_key: true
      t.string :title, null: false
      t.string :url, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :event_content_documents, [:event_content_id, :position]
  end
end
