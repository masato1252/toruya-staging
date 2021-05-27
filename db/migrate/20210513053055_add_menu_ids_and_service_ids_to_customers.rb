class AddMenuIdsAndServiceIdsToCustomers < ActiveRecord::Migration[5.2]
  def change
    # https://stackoverflow.com/a/34078666/609365
    enable_extension "btree_gin"
    # https://www.postgresql.org/docs/9.1/arrays.html
    add_column :customers, :menu_ids, :string, array: true
    change_column_default :customers, :menu_ids, "{}"
    add_column :customers, :online_service_ids, :string, array: true
    change_column_default :customers, :online_service_ids, "{}"

    # https://www.postgresql.org/docs/9.2/textsearch-indexes.html
    add_index :customers, [:user_id, :menu_ids, :online_service_ids], using: 'gin', name: "used_services_index"
  end

  def down
    remove_column :customers, :menu_ids
    remove_column :customers, :online_service_ids
    remove_index  :customers, name: "used_services_index"
  end
end
