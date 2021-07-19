class BackfillAddPositionAndAfterLastMessageDaysCustomMessages < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    CustomMessage.unscoped.in_batches do |relation|
      relation.update_all position: 0, after_last_message_days: 3, receiver_ids: []
      sleep(0.01)
    end
  end
end
