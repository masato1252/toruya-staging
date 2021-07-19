class BackfillAddPositionAndAfterLastMessageDaysCustomMessages < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    CustomMessage.unscoped.in_batches do |relation|
      relation.update_all after_days: nil, receiver_ids: []
      sleep(0.01)
    end
  end

  def down
  end
end
