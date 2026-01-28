class AddReservationAndCustomMessageToSocialMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :social_messages, :reservation_id, :integer
    add_column :social_messages, :custom_message_id, :integer
    
    add_index :social_messages, :reservation_id
    add_index :social_messages, [:customer_id, :reservation_id, :custom_message_id], name: 'index_social_messages_on_duplicate_check'
  end
end
