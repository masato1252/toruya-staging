class AddInternalNameToSalePages < ActiveRecord::Migration[6.0]
  def change
    add_column :sale_pages, :internal_name, :string
  end
end
