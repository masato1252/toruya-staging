class TweakShopsTables < ActiveRecord::Migration[5.2]
  def change
    change_column_null(:shops, :email, true)
    change_column_null(:shops, :phone_number, true)
  end
end
