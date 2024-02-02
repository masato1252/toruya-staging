# frozen_string_literal: true

class SiteRouting
  attr_reader :h

  def initialize(view_context)
    @h = view_context
  end

  # TODO: controller and view required
  def settings_user_menus_path(user, shop_id)
    if from_line_bot
      h.lines_user_bot_settings_menus_path(user.id, shop_id)
    else
      h.settings_user_menus_path(user, shop_id: shop_id)
    end
  end

  # TODO: controller and view required
  def new_settings_user_reservation_setting_path(user, shop_id)
    if from_line_bot
      h.new_lines_user_bot_settings_reservation_setting_path(user.id, shop_id)
    else
      h.new_settings_user_reservation_setting_path(user, shop_id: shop_id)
    end
  end

  def customers_path(business_owner_id, *args)
    options = args.extract_options!
    h.lines_user_bot_customers_path(options.merge(business_owner_id: business_owner_id))
  end

  def reservation_form_path(reservation, *args)
    h.form_lines_user_bot_shop_reservations_path(reservation.shop.user_id, reservation.shop, reservation, *args)
  end

  # TODO: controller and view required
  def edit_settings_user_staff_path(user, staff, shop_id)
    from_line_bot ? h.edit_lines_user_bot_settings_staff_path(business_owner_id: user.id, id: staff.id) : h.edit_settings_user_staff_path(user, staff, shop_id: shop_id)
  end

  def member_path(*args)
    from_line_bot ? h.lines_user_bot_schedules_path(*args) : h.member_path(*args)
  end

  def schedule_date_path(*args)
    h.date_lines_user_bot_schedules_path(*args)
  end

  def custom_schedule_path(*args)
    h.lines_user_bot_custom_schedule_path(*args)
  end

  def custom_schedules_path(*args)
    h.lines_user_bot_custom_schedules_path(*args)
  end

  def check_out_shop_reservation_states_path(*args)
    h.check_out_lines_user_bot_shop_reservation_states_path(*args)
  end

  def check_in_shop_reservation_states_path(*args)
    h.check_in_lines_user_bot_shop_reservation_states_path(*args)
  end

  def accept_in_group_shop_reservation_states_path(*args)
    h.accept_in_group_lines_user_bot_shop_reservation_states_path(*args)
  end

  def accept_shop_reservation_states_path(*args)
    h.accept_lines_user_bot_shop_reservation_states_path(*args)
  end

  def pend_shop_reservation_states_path(*args)
    h.pend_lines_user_bot_shop_reservation_states_path(*args)
  end

  def cancel_shop_reservation_states_path(*args)
    h.cancel_lines_user_bot_shop_reservation_states_path(*args)
  end

  def accept_customer_user_reservations_path(reservation, customer)
    from_line_bot ? h.accept_lines_user_bot_customer_reservations_path(reservation.user_id, reservation, customer) : h.accept_customer_user_reservations_path(reservation.shop.user, reservation, customer)
  end

  def pend_customer_user_reservations_path(reservation, customer)
    h.pend_lines_user_bot_customer_reservations_path(business_owner_id: reservation.user_id, reservation_id: reservation.id, customer_id: customer.id)
  end

  def cancel_customer_user_reservations_path(reservation, customer)
    h.cancel_lines_user_bot_customer_reservations_path(reservation.user_id, reservation, customer)
  end

  def data_changed_user_customers_path(reservation_customer)
    data_changed_lines_user_bot_customers_path(reservation_customer.customer.user_id, reservation_customer)
  end

  def save_changes_user_customers_path(reservation_customer)
    h.save_changes_lines_user_bot_customers_path(reservation_customer.customer.user_id, reservation_customer)
  end

  def create_reservation_warnings_path(*args)
    from_line_bot ? h.create_reservation_lines_user_bot_warnings_path(*args) : h.create_reservation_warnings_path(*args)
  end

  def customer_show_path(*args)
    from_line_bot ? h.lines_user_bot_customers_path(*args) : h.user_customers_path(*args)
  end

  private

  def from_line_bot
    h.from_line_bot
  end
end
