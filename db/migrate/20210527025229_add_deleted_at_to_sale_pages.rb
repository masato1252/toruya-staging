class AddDeletedAtToSalePages < ActiveRecord::Migration[5.2]
  def change
    add_column :sale_pages, :deleted_at, :datetime, null: true
    remove_index :sale_pages, name: :index_sale_pages_on_user_id
    add_index :sale_pages, [:user_id, :deleted_at], name: :sale_page_index
  end
end
