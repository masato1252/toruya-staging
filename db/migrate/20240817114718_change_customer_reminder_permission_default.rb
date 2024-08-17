class ChangeCustomerReminderPermissionDefault < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_column_default :customers, :reminder_permission, true
    end
  end
end
