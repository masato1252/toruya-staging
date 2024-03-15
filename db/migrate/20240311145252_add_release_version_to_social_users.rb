class AddReleaseVersionToSocialUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :social_users, :release_version, :string
  end
end
