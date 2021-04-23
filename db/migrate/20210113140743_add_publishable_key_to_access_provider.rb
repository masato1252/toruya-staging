class AddPublishableKeyToAccessProvider < ActiveRecord::Migration[5.2]
  def change
    add_column :access_providers, :publishable_key, :string
  end
end
