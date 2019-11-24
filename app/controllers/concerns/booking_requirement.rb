module BookingRequirement
  extend ActiveSupport::Concern

  included do
    before_action :checking_booking_requirement
  end

  def checking_booking_requirement
    if is_owner
      return unless session[:booking_settings_tour]
      first_undo_task = booking_settings_presenter.first_undo_task

      if first_undo_task
        return if first_undo_task.accessable_controller_in_tour.member?(params[:controller])

        redirect_to first_undo_task.setting_path
      end

      if booking_settings_presenter.completed? && session[:booking_settings_tour]
        session.delete(:booking_settings_tour)
      end
    end
  end
end
