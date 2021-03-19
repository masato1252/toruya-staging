# frozen_string_literal: true

class RemoveSocialMessagesUniqueIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :social_messages, name: :social_message_customer_index
    add_index :social_messages, [:social_account_id, :social_customer_id], name: :social_message_customer_index
  end
end
