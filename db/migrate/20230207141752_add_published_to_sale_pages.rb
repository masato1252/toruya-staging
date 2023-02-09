class AddPublishedToSalePages < ActiveRecord::Migration[6.0]
  def change
    add_column :sale_pages, :published, :boolean
    change_column_default :sale_pages, :published, true

    SalePage.update_all(published: true)
  end
end
