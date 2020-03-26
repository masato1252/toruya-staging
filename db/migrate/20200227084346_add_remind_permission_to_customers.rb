class AddRemindPermissionToCustomers < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :reminder_permission, :boolean, default: false
  end
end
