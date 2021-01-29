class AddSlugToSalePagesAndBookingPage < ActiveRecord::Migration[5.2]
  def change
    add_column :sale_pages, :slug, :string
    add_index :sale_pages, :slug, unique: true
    add_column :booking_pages, :slug, :string
    add_index :booking_pages, :slug, unique: true
  end
end
