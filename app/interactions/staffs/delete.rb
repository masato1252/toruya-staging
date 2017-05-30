module Staffs
  class Delete < ActiveInteraction::Base
    object :staff

    def execute
      staff.update_columns(deleted_at: Time.zone.now)
      NotificationMailer.staff_deleted(staff).deliver_later
    end
  end
end
