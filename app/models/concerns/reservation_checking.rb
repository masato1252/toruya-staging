module ReservationChecking
  extend ActiveSupport::Concern

  included do
    before_destroy :check_reservations
  end

  private

  def check_reservations
    if reservation_staffs.exists?
      errors.add(:base, "There are reservations exists belongs to this staff.")
      throw(:abort)
    end
  end
end
