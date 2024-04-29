class AddMapPublicToSalePages < ActiveRecord::Migration[7.0]
  def change
    add_column :sale_pages, :map_public, :boolean, default: false, null: true
  end
end
