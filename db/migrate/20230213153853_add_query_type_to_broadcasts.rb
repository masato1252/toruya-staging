class AddQueryTypeToBroadcasts < ActiveRecord::Migration[6.0]
  def change
    add_column :broadcasts, :query_type, :string
  end
end
