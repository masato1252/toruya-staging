module ReservationChecking
  extend ActiveSupport::Concern

  included do
    before_destroy :check_reservations
  end

  private

  def check_reservations
    if reservations.active.exists?
      errors.add(:base, "Undeleteable. There are reservations exists belongs to it.")
      throw(:abort)
    end
  end
end
