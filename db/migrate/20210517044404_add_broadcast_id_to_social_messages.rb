class AddBroadcastIdToSocialMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :social_messages, :broadcast_id, :integer, null: true
    add_index :social_messages, :broadcast_id
  end
end
