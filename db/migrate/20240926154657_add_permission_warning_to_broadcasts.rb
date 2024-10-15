class AddPermissionWarningToBroadcasts < ActiveRecord::Migration[7.0]
  def change
    add_column :broadcasts, :customers_permission_warning, :boolean, default: false

    Broadcast.find_each do |broadcast|
      customers = Broadcasts::FilterCustomers.run!(broadcast: broadcast)
      broadcast.update(customers_permission_warning: customers.any? { |customer| !customer.reminder_permission })
    end
  end
end
