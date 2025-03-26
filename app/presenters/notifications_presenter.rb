# frozen_string_literal: true

require "site_routing"

class NotificationsPresenter
  attr_reader :user, :h, :reservations_approval_flow, :my_calendar
  delegate :link_to, to: :h

  def initialize(h, user, params = {})
    @h = h
    @user = user
    @reservation_id = params[:reservation_id]
    @my_calendar = params[:my_calendar]
  end

  def data
    Array.wrap(new_pending_reservations) +
      Notifications::PendingCustomerReservationsPresenter.new(h, user).data
  end

  def recent_pending_reservations
    @recent_pending_reservations ||= ReservationStaff
      .pending
      .where(staff_id: staff_ids)
      .includes(reservation: :shop)
      .where("reservations.start_time > ?", 1.day.ago)
      .where("reservations.aasm_state": :pending, "reservations.deleted_at": nil)
      .order("reservations.start_time ASC, reservations.id ASC")
  end

  private

  def new_pending_reservations
    @new_pending_reservations_message ||= if recent_pending_reservations.present?
      message = "#{I18n.t("notifications.pending_reservation_need_confirm", number: recent_pending_reservations.count)}"

      if @reservation_id
        reservations = recent_pending_reservations.map(&:reservation)
        reservation_ids = reservations.map(&:id)
        matched_index = reservation_ids.find_index {|r_id| r_id == @reservation_id.to_i }
      end

      if matched_index
        text = "<strong>#{matched_index + 1}/#{reservation_ids.size}</strong>"

        if matched_index == 0
          previous_reservation_id = nil
          next_reservation_id = reservation_ids[matched_index + 1]
        elsif matched_index + 1 == reservation_ids.size
          previous_reservation_id = reservation_ids[matched_index - 1]
          next_reservation_id = nil
        else
          previous_reservation_id = reservation_ids[matched_index - 1]
          next_reservation_id = reservation_ids[matched_index + 1]
        end

        if previous_reservation_id
          previous_path = SiteRouting.new(h).schedule_date_path(reservations[matched_index - 1].user_id, reservations[matched_index - 1].start_time.to_fs(:date), previous_reservation_id, popup_disabled: true)
        end

        if next_reservation_id
          next_path = SiteRouting.new(h).schedule_date_path(reservations[matched_index + 1].user_id, reservations[matched_index + 1].start_time.to_fs(:date), next_reservation_id, popup_disabled: true)
        end
      else
        oldest_res = recent_pending_reservations.first&.reservation

        text = I18n.t("notifications.pending_reservation_confirm")
        path = SiteRouting.new(h).schedule_date_path(oldest_res.user_id, oldest_res.start_time.to_fs(:date), oldest_res.id, popup_disabled: true)
      end

      if path
        "#{message} #{link_to(text.html_safe, path)}"
      else
        @reservations_approval_flow = true

        "#{message} #{link_to('<i class="fa fa-caret-square-left fa-2x" aria-hidden="true"></i>'.html_safe, previous_path) if previous_path}
        #{text}
        #{link_to('<i class="fa fa-caret-square-right fa-2x" aria-hidden="true"></i>'.html_safe, next_path) if next_path}"
      end
    else
      []
    end
  end

  def staff_ids
    @staff_ids ||=
      if my_calendar
        Current.user.social_user.staffs.map(&:id)
      else
        if Current.user.current_staff(user)
          [Current.user.current_staff(user).id]
        elsif Current.admin_debug
          [Current.business_owner.current_staff(user).id]
        end
      end
  end

  def working_shop_owners
    @working_shop_owners ||=
      if my_calendar
        Current.user.social_user.manage_accounts
      else
        [Current.business_owner]
      end
  end
end
