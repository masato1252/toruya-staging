class AddOwnerIdAndProductToVisits < ActiveRecord::Migration[5.2]
  def change
    add_column :ahoy_visits, :owner_id, :string, null: true
    add_column :ahoy_visits, :product_id, :integer, null: true
    add_column :ahoy_visits, :product_type, :string, null: true

    add_index :ahoy_visits, :owner_id
    add_index :ahoy_visits, [:product_type, :product_id]
  end
end
