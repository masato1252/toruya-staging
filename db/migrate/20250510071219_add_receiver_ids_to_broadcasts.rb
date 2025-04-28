class AddReceiverIdsToBroadcasts < ActiveRecord::Migration[7.0]
  def change
    add_column :broadcasts, :receiver_ids, :jsonb, default: []
    add_reference :broadcasts, :builder, :polymorphic => true, null: true
  end
end
