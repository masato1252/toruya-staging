class AddPrimaryPhoneNumberAndEmailToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :customer_email, :string
    add_column :customers, :customer_phone_number, :string

    Customer.find_each do |customer|
      customer.update_columns(
        customer_email: customer.email,
        customer_phone_number: Phonelib.parse(customer.mobile_phone_number).international(false)
      )
    end

    add_index :customers, [:user_id, :customer_email]
    add_index :customers, [:user_id, :customer_phone_number], unique: true
  end
end
