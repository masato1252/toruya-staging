class AddPostionAfterLastMessageDaysReceiverIdsToCustomMessages < ActiveRecord::Migration[6.0]
  def up
    remove_index :custom_messages, name: :index_custom_messages_on_service_type_and_service_id
    add_column :custom_messages, :after_days, :integer
    add_column :custom_messages, :receiver_ids, :string, array: true, default: []
    add_index :custom_messages, [:service_type, :service_id, :scenario, :after_days], name: :sequence_message_index
  end

  def down
    remove_index :custom_messages, name: :sequence_message_index
    remove_column :custom_messages, :after_days
    remove_column :custom_messages, :receiver_ids
    add_index :custom_messages, [:service_type, :service_id], name: :index_custom_messages_on_service_type_and_service_id
  end
end
