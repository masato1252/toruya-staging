class CreateShopMenuRepeatingDates < ActiveRecord::Migration[5.0]
  def change
    create_table :shop_menu_repeating_dates do |t|
      t.references :shop, null: false
      t.references :menu, null: false
      t.string :dates, array: true, default: []
      t.date :end_date
      t.timestamps
    end

    add_index :shop_menu_repeating_dates, [:shop_id, :menu_id], unique: true
  end
end
