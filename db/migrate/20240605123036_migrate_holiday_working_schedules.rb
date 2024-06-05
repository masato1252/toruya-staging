class MigrateHolidayWorkingSchedules < ActiveRecord::Migration[7.0]
  def change
    Shop.where(holiday_working: true).find_each do |shop|
      outcome = BusinessSchedules::Update.run(
        shop: shop,
        business_state: "opened",
        day_of_week: BusinessSchedule::HOLIDAY_WORKING_WDAY,
        business_schedules: [
          {
            "start_time" => "09:00",
            "end_time" => "17:00"
          }
        ]
      )
    end
  end
end
