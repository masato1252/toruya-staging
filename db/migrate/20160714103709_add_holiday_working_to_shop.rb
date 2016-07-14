class AddHolidayWorkingToShop < ActiveRecord::Migration[5.0]
  def change
    add_column :shops, :holiday_working, :boolean
  end
end
