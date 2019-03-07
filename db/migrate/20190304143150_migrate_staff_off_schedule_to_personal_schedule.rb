class MigrateStaffOffScheduleToPersonalSchedule < ActiveRecord::Migration[5.1]
  def change
    CustomSchedule.transaction do
      reference_ids = CustomSchedule.closed.where.not(reference_id: nil).distinct(:reference_id).pluck(:reference_id)

      reference_ids.each do |reference_id|
        schedule = CustomSchedule.find_by(reference_id: reference_id)

        schedule.staff.staff_account.user.custom_schedules.create!(
          open: schedule.open,
          start_time: schedule.start_time,
          end_time: schedule.end_time,
          reason: schedule.reason,
          created_at: schedule.created_at,
          updated_at: schedule.updated_at
        )

        CustomSchedule.where(reference_id: reference_id).destroy_all
      end
    end

    remove_column :custom_schedules, :reference_id
  end
end
