module AccountRequirement
  extend ActiveSupport::Concern

  # Bottom Checking First
  included do
    before_action :require_menu
    before_action :require_reservation_settings
    before_action :require_working_times
    before_action :require_staffs
    before_action :require_business_hours
    before_action :require_shop
    before_action :require_contacts
    before_action :require_user_name
  end

  def require_user_name
    if !current_user.name
      flash.now[:alert] = "Please go to #{view_context.link_to("Account page", new_settings_profile_path)} to fill your information".html_safe
    end
  end

  def require_contacts
    if !current_user.uid || !current_user.contact_groups.connected.exists? || current_user.contact_groups.unconnect.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Contacts page", settings_contact_groups_path)} to connect your google account with your toruya groups".html_safe
    end
  end

  def require_shop
    if !current_user.shops.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Shop page", new_settings_shop_path)} to create your shops".html_safe
    end
  end

  def require_menu
    if !current_user.menus.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Menu page", new_settings_menu_path)} to create your Menu".html_safe
    end
  end

  def require_business_hours
    if !BusinessSchedule.where(shop_id: current_user.shop_ids).exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Business Schedule page", settings_business_schedules_path)} to set your business schedule".html_safe
    end
  end

  def require_staffs
    if !current_user.staffs.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Staff page", new_settings_staff_path)} to create your staffs".html_safe
    end
  end

  def require_working_times
    if !BusinessSchedule.where(staff_id: current_user.staff_ids).exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Staff business_schedules page", settings_working_time_staffs_path)} to set their schedules".html_safe
    end
  end

  def require_reservation_settings
    if !current_user.reservation_settings.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Reservation Settings page", new_settings_reservation_setting_path)} to set your reservation settings".html_safe
    end
  end
end
