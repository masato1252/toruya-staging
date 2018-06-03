module Staffs
  class Delete < ActiveInteraction::Base
    object :staff

    def execute
      if staff.staff_account
        if staff.staff_account.owner?
          # do nothing, owner staff is not deleteable
          return
        else
          staff.staff_account.disabled!
        end
      end

      staff.update_columns(deleted_at: Time.zone.now)

      if Reservation.future.joins(:reservation_staffs).where("reservation_staffs.staff_id = ?", staff.id).exists?
        NotificationMailer.staff_deleted(staff).deliver_later
      end
    end
  end
end
