class SiteRouting
  attr_reader :h

  def initialize(view_context)
    @h = view_context
  end

  # TODO: controller and view required
  def settings_user_menus_path(user, shop_id)
    if from_line_bot
      h.lines_user_bot_settings_menus_path
    else
      h.settings_user_menus_path(user, shop_id: shop_id)
    end
  end

  # TODO: controller and view required
  def new_settings_user_reservation_setting_path(user, shop_id)
    if from_line_bot
      h.new_lines_user_bot_settings_reservation_setting_path
    else
      h.new_settings_user_reservation_setting_path(user, shop_id: shop_id)
    end
  end

  # TODO: controller and view required
  def customers_path(*args)
    if from_line_bot
      h.lines_user_bot_customers_path(*args)
    else
      h.user_customers_path(*args)
    end
  end

  def reservation_form_path(reservation, *args)
    if from_line_bot
      h.form_lines_user_bot_shop_reservations_path(reservation.shop, reservation, *args)
    else
      h.form_shop_reservations_path(reservation.shop, reservation, *args)
    end
  end

  # TODO: controller and view required
  def edit_settings_user_staff_path(user, staff, shop_id)
    from_line_bot ? h.edit_lines_user_bot_settings_staff_path(staff) : h.edit_settings_user_staff_path(user, staff, shop_id: shop_id)
  end

  def member_path(*args)
    from_line_bot ? h.lines_user_bot_schedules_path(*args) : h.member_path(*args)
  end

  def schedule_date_path(*args)
    from_line_bot ? h.date_lines_user_bot_schedules_path(*args) : h.date_member_path(*args)
  end

  def custom_schedule_path(*args)
    from_line_bot ? h.lines_user_bot_custom_schedule_path(*args) : h.custom_schedule_path(*args)
  end

  def custom_schedules_path(*args)
    from_line_bot ? h.lines_user_bot_custom_schedules_path(*args) : h.custom_schedules_path(*args)
  end

  private

  def from_line_bot
    h.from_line_bot
  end
end
