# frozen_string_literal: true

class AddLevelColumnToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :level, :integer, default: 0, null: false
  end
end
