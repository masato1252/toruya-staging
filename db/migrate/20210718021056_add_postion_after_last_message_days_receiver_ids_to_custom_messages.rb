class AddPostionAfterLastMessageDaysReceiverIdsToCustomMessages < ActiveRecord::Migration[6.0]
  def up
    add_column :custom_messages, :position, :integer
    change_column_default :custom_messages, :position, 0
    add_column :custom_messages, :after_last_message_days, :integer
    change_column_default :custom_messages, :after_last_message_days, 3
    add_column :custom_messages, :receiver_ids, :string, array: true, default: []
    remove_index :custom_messages, name: :index_custom_messages_on_service_type_and_service_id
    add_index :custom_messages, [:service_type, :service_id, :scenario], name: :sequence_message_index
  end

  def down
    remove_column :custom_messages, :position
    remove_column :custom_messages, :after_last_message_days
    remove_column :custom_messages, :receiver_ids
    remove_index :custom_messages, name: :sequence_message_index
    add_index :custom_messages, [:service_type, :service_id], name: :index_custom_messages_on_service_type_and_service_id
  end
end
