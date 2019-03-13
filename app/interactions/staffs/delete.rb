module Staffs
  class Delete < ActiveInteraction::Base
    object :staff

    validate :validate_owner

    def execute
      staff.transaction do
        if staff.staff_account
          staff.staff_account.disabled!
        end

        staff.update_columns(deleted_at: Time.current)

        if Reservation.future.active.joins(:reservation_staffs).where("reservation_staffs.staff_id = ?", staff.id).exists?
          NotificationMailer.staff_deleted(staff).deliver_later
        end

        staff.shop_staffs.destroy_all
        staff.staff_menus.destroy_all
        staff.contact_group_relations.destroy_all
      end
    end

    private

    def validate_owner
      if staff.staff_account&.owner?
        # do nothing, owner staff is not deleteable
        errors.add(:staff, :undeleteable)
      end
    end
  end
end
