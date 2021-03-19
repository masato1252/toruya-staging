# frozen_string_literal: true

class AddCompanyProfile < ActiveRecord::Migration[5.1]
  def change
    add_column :profiles, :company_zip_code, :string
    add_column :profiles, :company_address, :string
    add_column :profiles, :company_phone_number, :string
  end
end
