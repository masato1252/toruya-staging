class CreateSocialUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :social_users do |t|
      t.references :user
      t.string :social_service_user_id, null: false
      t.string :social_user_name
      t.string :social_user_picture_url

      t.timestamps
    end

    add_index :social_users, [:user_id, :social_service_user_id], unique: true, name: :social_user_unique_index
  end
end
