class AddQueryTypeToBroadcasts < ActiveRecord::Migration[6.0]
  def change
    add_column :broadcasts, :query_type, :string

    Broadcast.find_each do |broadcast|
      case broadcast.query["filters"][0]["field"]
      when "menu_ids"
        broadcast.update_columns(query_type: "menu")
      when "online_service_ids"
        broadcast.update_columns(query_type: "online_service")
      end
    end
  end
end
