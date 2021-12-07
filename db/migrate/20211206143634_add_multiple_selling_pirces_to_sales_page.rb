class AddMultipleSellingPircesToSalesPage < ActiveRecord::Migration[6.0]
  def change
    add_column :sale_pages, :selling_multiple_times_price, :string, array: true, default: []
  end
end
