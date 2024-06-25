class MigrateBusinessScheduleDates < ActiveRecord::Migration[7.0]
  def change
    BusinessSchedule.where(day_of_week: 7).update_all(day_of_week: 0)
  end
end
