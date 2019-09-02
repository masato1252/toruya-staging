class NotificationsPresenter
  attr_reader :current_user, :h
  delegate :link_to, to: :h

  def initialize(h, current_user, params = {})
    @h = h
    @current_user = current_user
    @reservation_id = params[:reservation_id]
  end

  def data
    Array.wrap(new_pending_reservations) +
      Notifications::PendingCustomerReservationsPresenter.new(h, current_user).data +
      Notifications::NonGroupCustomersPresenter.new(h, current_user).data +
      new_staff_accounts +
      empty_reservation_setting_users +
      empty_menu_shops +
      Array(basic_settings_tour)
  end

  def recent_pending_reservations
    @recent_pending_reservations ||= ReservationStaff.pending.where(staff_id: staff_ids).includes(reservation: :shop).where("reservations.aasm_state": :pending, "reservations.deleted_at": nil).order("reservations.start_time ASC, reservations.id ASC")
  end

  def recent_pending_customer_reservations
    ReservationCustomer.pending.includes(reservation: [:shop, :reservation_staffs]).where("reservation_staffs.staff_id": staff_ids).order("reservation_customers.created_at ASC")
  end

  private

  def new_pending_reservations
    if recent_pending_reservations.present?
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
          previous_path = h.date_member_path(reservations[matched_index - 1].start_time.to_s(:date), previous_reservation_id, popup_disabled: true)
        end

        if next_reservation_id
          next_path = h.date_member_path(reservations[matched_index + 1].start_time.to_s(:date), next_reservation_id, popup_disabled: true)
        end
      else
        oldest_res = recent_pending_reservations.first&.reservation

        text = I18n.t("notifications.pending_reservation_confirm")
        path = h.date_member_path(oldest_res.start_time.to_s(:date), oldest_res.id, popup_disabled: true)
      end

      if path
        "#{message} #{link_to(text.html_safe, path)}"
      else
        "#{message} #{link_to('<i class="fa fa-caret-square-o-left fa-2x" aria-hidden="true"></i>'.html_safe, previous_path) if previous_path}
        #{text}
        #{link_to('<i class="fa fa-caret-square-o-right fa-2x" aria-hidden="true"></i>'.html_safe, next_path) if next_path}"
      end
    else
      []
    end
  end

  def new_staff_accounts
    Staff.where(user: current_user).active_without_data.includes(:staff_account).map do |staff|
      "#{I18n.t("settings.staff_account.new_staff_active")} #{link_to(I18n.t("settings.staff_account.staff_setting"), h.edit_settings_user_staff_path(current_user, staff, shop_id: current_user.shop_ids.first))}" if h.ability(staff.user).can?(:edit, staff)
    end.compact
  end

  def empty_reservation_setting_users
    current_user.staff_accounts.includes(:owner).each_with_object([]) do |staff_account, array|
      # XXX: Owner should solve this issue in basic settings warnings
      next if staff_account.owner?

      data = Notifications::EmptyReservationSettingUserPresenter.new(h, current_user).data(staff_account: staff_account)

      array << data if data
    end
  end

  def empty_menu_shops
    h.working_shop_options(include_user_own: true).each_with_object([]) do |shop_option, array|
      owner = shop_option.owner
      shop = shop_option.shop

      data = if current_user == owner
               if basic_settings_tour&.empty? # basic_settings_tour finished
                 Notifications::EmptyMenuShopPresenter.new(h, current_user).data(owner: owner, shop: shop)
               end
             else
               Notifications::EmptyMenuShopPresenter.new(h, current_user).data(owner: owner, shop: shop)
             end

      array << data if data
    end
  end

  def basic_settings_tour
    return @basic_settings_tour_data if defined?(@basic_settings_tour_data)

    @basic_settings_tour_data =
      begin
        data = Notifications::BasicSettingTourPresenter.new(h, current_user).data

        if data
          if h.cookies[:basic_settings_tour_warning_hidden]
            nil # basic_settings_tour doesn't finish but don't show it
          else
            [data]
          end
        else
          []
        end
      end
  end

  def staff_ids
    @staff_ids ||= current_user.staff_accounts.active.pluck(:staff_id)
  end

  # XXX: includes current_user themselves
  def working_shop_owners
    @working_shop_owners ||= current_user.staff_accounts.active.map(&:owner)
  end
end
