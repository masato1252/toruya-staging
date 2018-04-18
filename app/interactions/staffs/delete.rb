module Staffs
  class Delete < ActiveInteraction::Base
    object :staff

    def execute
      staff.update_columns(deleted_at: Time.zone.now)
      staff.staff_account.disabled! if staff.staff_account

      if Reservation.future.joins(:reservation_staffs).where("reservation_staffs.staff_id = ?", staff.id).exists?
        NotificationMailer.staff_deleted(staff).deliver_later
      end
    end
  end
end
