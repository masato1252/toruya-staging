# frozen_string_literal: true

class AddBindAllToContactGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :contact_groups, :bind_all, :boolean, after: :name
    add_index :contact_groups, [:user_id, :bind_all], unique: true
  end
end
