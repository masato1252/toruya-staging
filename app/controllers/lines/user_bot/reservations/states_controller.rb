# frozen_string_literal: true

class Lines::UserBot::Reservations::StatesController < Lines::UserBotDashboardController
  before_action :authorize_reservation

  def pend
    outcome = ::Reservations::Pend.run(reservation: reservation, current_staff: current_user_staff)

    redirect_back fallback_location: mine_lines_user_bot_schedules_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def accept
    outcome = ::Reservations::Accept.run(reservation: reservation, current_staff: current_user_staff)

    notify_user_customer_reservation_confirmation_message
    redirect_back fallback_location: mine_lines_user_bot_schedules_path
  end

  def accept_in_group
    outcome = ::Reservations::Accept.run(reservation: reservation, current_staff: current_user_staff)

    if outcome.valid?
      notify_user_customer_reservation_confirmation_message
      recent_pending_reservations = NotificationsPresenter.new(view_context, current_user).recent_pending_reservations

      if recent_pending_reservations.exists?
        next_pending_reservation = recent_pending_reservations.first.reservation

        redirect_to date_lines_user_bot_schedules_path(next_pending_reservation.user_id, next_pending_reservation.start_time.to_fs(:date), next_pending_reservation.id)
      else
        redirect_back fallback_location: mine_lines_user_bot_schedules_path
      end
    else
      redirect_back fallback_location: mine_lines_user_bot_schedules_path
    end
  end

  def check_in
    reservation.check_in!
    redirect_back fallback_location: mine_lines_user_bot_schedules_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def check_out
    Reservations::CheckOut.run(reservation: reservation)
    redirect_back fallback_location: mine_lines_user_bot_schedules_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def cancel
    Reservations::Cancel.run(reservation: reservation)
    redirect_back fallback_location: mine_lines_user_bot_schedules_path, notice: I18n.t("reservation.canceled_successfully_message")
  end

  private

  def reservation
    @reservation ||= Reservation.find(params[:reservation_id])
  end

  def authorize_reservation
    authorize! :edit, reservation
  end
end
