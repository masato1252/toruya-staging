# frozen_string_literal: true

class CreateDocsTables < ActiveRecord::Migration[6.1]
  def change
    create_table :docs do |t|
      t.string :slug, null: false
      t.integer :status, null: false, default: 1
      t.string :title, null: false
      t.text :description
      t.string :document_url, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :docs, :slug, unique: true
    add_index :docs, :deleted_at
    add_index :docs, :status

    create_table :doc_line_users do |t|
      t.string :line_user_id, null: false
      t.string :display_name
      t.string :picture_url
      t.string :email

      t.timestamps
    end

    add_index :doc_line_users, :line_user_id, unique: true

    create_table :doc_downloads do |t|
      t.references :doc, null: false, foreign_key: true
      t.references :doc_line_user, null: false, foreign_key: true
      t.datetime :first_visited_at
      t.datetime :first_downloaded_at
      t.integer :download_count, null: false, default: 0
      t.text :referrer

      t.timestamps
    end

    add_index :doc_downloads, [:doc_id, :doc_line_user_id], unique: true
  end
end
