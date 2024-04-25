class AddDraftToSalePages < ActiveRecord::Migration[7.0]
  def change
    add_column :sale_pages, :draft, :boolean, default: false
  end
end
