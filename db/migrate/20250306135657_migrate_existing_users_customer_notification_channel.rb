class MigrateExistingUsersCustomerNotificationChannel < ActiveRecord::Migration[7.0]
  def change
    UserSetting.find_each do |user_setting|
      user_setting.update(customer_notification_channel: "line")
    end
  end
end