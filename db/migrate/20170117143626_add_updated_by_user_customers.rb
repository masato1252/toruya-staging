class AddUpdatedByUserCustomers < ActiveRecord::Migration[5.0]
  def change
    add_column :customers, :updated_by_user_id, :integer
  end
end
