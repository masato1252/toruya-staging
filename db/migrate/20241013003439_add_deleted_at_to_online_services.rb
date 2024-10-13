class AddDeletedAtToOnlineServices < ActiveRecord::Migration[7.0]
  def change
    add_column :online_services, :deleted_at, :datetime
  end
end
