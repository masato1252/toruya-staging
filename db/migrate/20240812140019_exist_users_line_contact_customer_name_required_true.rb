class ExistUsersLineContactCustomerNameRequiredTrue < ActiveRecord::Migration[7.0]
  def change
    User.find_each do |user|
      user.user_setting.update(line_contact_customer_name_required: true)
    end
  end
end
