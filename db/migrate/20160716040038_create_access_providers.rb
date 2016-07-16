class CreateAccessProviders < ActiveRecord::Migration[5.0]
  def change
    create_table :access_providers do |t|
      t.string :access_token, :refresh_token, :provider, :uid
      t.integer :user_id

      t.timestamps
    end

    add_index :access_providers, [:provider, :uid]
  end
end
