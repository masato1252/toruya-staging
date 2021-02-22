class AddOnlineServiceRequiredColumnToSalePages < ActiveRecord::Migration[5.2]
  def change
    add_column :sale_pages, :introduction_video_url, :string
    add_column :sale_pages, :quantity, :integer
    add_column :sale_pages, :selling_end_at, :datetime
    add_column :sale_pages, :selling_start_at, :datetime
    add_column :sale_pages, :normal_price_amount_cents, :decimal
    add_column :sale_pages, :selling_price_amount_cents, :decimal
  end
end
