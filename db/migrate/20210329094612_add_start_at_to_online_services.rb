class AddStartAtToOnlineServices < ActiveRecord::Migration[5.2]
  def change
    add_column :online_services, :start_at, :datetime
  end
end
