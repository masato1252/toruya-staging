# frozen_string_literal: true

class RemoveUsersLevelColumn < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :level
  end
end
