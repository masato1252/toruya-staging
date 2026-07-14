# frozen_string_literal: true

class Lines::UserBot::Reservations::StatesController < Lines::UserBotDashboardController
  before_action :authorize_reservation, unless: :compat_read_data_plane?

  def pend
    return compat_transition("pend") if compat_read_data_plane?

    outcome = ::Reservations::Pend.run(reservation: reservation, current_staff: current_user_staff)

    redirect_back fallback_location: mine_lines_user_bot_schedules_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def accept
    return compat_transition("accept") if compat_read_data_plane?

    outcome = ::Reservations::Accept.run(reservation: reservation, current_staff: current_user_staff)

    notify_user_customer_reservation_confirmation_message
    redirect_back fallback_location: mine_lines_user_bot_schedules_path
  end

  def accept_in_group
    return compat_transition("accept_in_group") if compat_read_data_plane?

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
    return compat_transition("check_in") if compat_read_data_plane?

    reservation.check_in!
    redirect_back fallback_location: mine_lines_user_bot_schedules_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def check_out
    return compat_transition("check_out") if compat_read_data_plane?

    Reservations::CheckOut.run(reservation: reservation)
    redirect_back fallback_location: mine_lines_user_bot_schedules_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def cancel
    return compat_transition("cancel") if compat_read_data_plane?

    Reservations::Cancel.run(reservation: reservation)
    redirect_back fallback_location: mine_lines_user_bot_schedules_path, notice: I18n.t("reservation.canceled_successfully_message")
  end

  private

  def compat_transition(action)
    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    result = compat_v1_post(
      "/lines/user_bot/owner/#{owner_id}/shops/#{params[:shop_id]}/reservations/#{params[:reservation_id]}/states/#{action}",
      { current_user_id: resolve_compat_current_user_id(nil) }
    )
    fallback = mine_lines_user_bot_schedules_path
    unless result&.dig("status") == "successful"
      redirect_back fallback_location: fallback,
                    alert: result&.dig("error_message") || I18n.t("common.operation_failed", default: "更新に失敗しました")
      return
    end

    notice = if action == "cancel"
               I18n.t("reservation.canceled_successfully_message")
             elsif action == "accept" || action == "accept_in_group"
               nil
             else
               I18n.t("reservation.update_successfully_message")
             end
    redirect_back fallback_location: fallback, notice: notice
  end

  def reservation
    @reservation ||= Reservation.find(params[:reservation_id])
  end

  def authorize_reservation
    authorize! :edit, reservation
  end
end
