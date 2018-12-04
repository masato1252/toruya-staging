module ReservationChecking
  extend ActiveSupport::Concern

  included do
    before_destroy :check_reservations
  end

  private

  def check_reservations
    if reservations.exists?
      errors.add(:base, "Undeleteable, there are reservations exists belongs to this.")
      throw(:abort)
    end
  end
end
