class BasicSettingsPresenter
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def current_step
    if !customers_settings_completed?
      "welcome"
    elsif !shops_settings_completed?
      "shop"
    elsif !business_hours_settings_completed?
      "business_schedule"
    elsif !working_time_settings_completed?
      "working_time"
    elsif !reservation_settings_completed?
      "reservation_setting"
    elsif !menu_settings_completed?
      "menu"
    end
  end

  def completed?
    personal_scheduled_enabled? && customers_management_enabled? && reservation_management_enabled?
  end

  def personal_scheduled_enabled?
    profile_settings_completed?
  end

  def profile_settings_completed?
    return @profile_settings_completed if defined?(@profile_settings_completed)

    @profile_settings_completed = user.profile
  end

  def customers_management_enabled?
    customers_settings_completed?
  end

  def customers_settings_completed?
    return @customers_settings_completed if defined?(@customers_settings_completed)

    @customers_settings_completed = !user.uid && user.contact_groups.connected.exists?
  end

  def reservation_management_enabled?
    shops_settings_completed? && business_hours_settings_completed? && working_time_settings_completed? && reservation_settings_completed? && menu_settings_completed?
  end

  def reservation_settings_completed_percentage
    completed_steps = 0
    completed_steps += 1 if shops_settings_completed?
    completed_steps += 1 if business_hours_settings_completed?
    completed_steps += 1 if working_time_settings_completed?
    completed_steps += 1 if reservation_settings_completed?
    completed_steps += 1 if menu_settings_completed?

    completed_steps/5.0
  end

  def shops_settings_completed?
    return @shops_settings_completed if defined?(@shops_settings_completed)

    @shops_settings_completed = user.shops.exists?
  end

  def business_hours_settings_completed?
    return @business_hours_settings_completed if defined?(@business_hours_settings_completed)

    @business_hours_settings_completed = BusinessSchedule.where(shop_id: user.shop_ids).exists?
  end

  def working_time_settings_completed?
    return @working_time_settings_completed if defined?(@working_time_settings_completed)

    @working_time_settings_completed = BusinessSchedule.where(staff_id: user.staff_ids).exists?
  end

  def reservation_settings_completed?
    return @reservation_settings_completed if defined?(@reservation_settings_completed)

    @reservation_settings_completed = user.reservation_settings.exists?
  end

  def menu_settings_completed?
    return @menu_settings_completed if defined?(@menu_settings_completed)

    @menu_settings_completed = user.menus.exists?
  end
end
