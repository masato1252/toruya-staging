# frozen_string_literal: true

class CreateSettingsCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :categories do |t|
      t.integer :user_id
      t.string :name

      t.timestamps
    end

    add_index :categories, :user_id
  end
end
