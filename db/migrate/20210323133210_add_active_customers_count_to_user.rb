class AddActiveCustomersCountToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :customers_count, :integer, default: 0
  end
end
