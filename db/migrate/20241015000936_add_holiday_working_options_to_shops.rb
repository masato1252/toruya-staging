class AddHolidayWorkingOptionsToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :holiday_working_option, :string, default: "holiday_schedule_without_business_schedule"
  end
end
