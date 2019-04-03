class TweakCustomersIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :customers, [:user_id, :contact_group_id, :deleted_at], name: :customers_basic_index
    remove_index :customers, [:rank_id]
    remove_index :customers, [:user_id]
    remove_index :customers, [:contact_group_id]
    remove_index :customers, [:user_id, :deleted_at]
  end
end
