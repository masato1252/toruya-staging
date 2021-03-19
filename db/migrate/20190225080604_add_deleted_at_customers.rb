# frozen_string_literal: true

class AddDeletedAtCustomers < ActiveRecord::Migration[5.1]
  def change
    add_column :customers, :deleted_at, :datetime
    add_index :customers, [:user_id, :deleted_at]
  end
end
