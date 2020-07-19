class CreateWebPushSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :web_push_subscriptions do |t|
      t.references :user
      t.string :endpoint
      t.string :p256dh_key
      t.string :auth_key
      t.timestamps
    end
  end
end
