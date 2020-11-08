class AddDetailsColumnsToCustomers < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :phone_numbers_details, :jsonb, default: []
    add_column :customers, :emails_details, :jsonb, default: []
    add_column :customers, :address_details, :jsonb, default: {}
  end
end
