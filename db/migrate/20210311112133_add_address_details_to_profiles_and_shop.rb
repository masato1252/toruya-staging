class AddAddressDetailsToProfilesAndShop < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :personal_address_details, :jsonb
    add_column :profiles, :company_address_details, :jsonb
    add_column :shops, :address_details, :jsonb
  end
end
