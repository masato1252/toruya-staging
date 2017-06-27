class AddEmailToAccessProvider < ActiveRecord::Migration[5.0]
  def change
    add_column :access_providers, :email, :string
  end
end
