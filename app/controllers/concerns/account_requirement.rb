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
    if !session[:user_name_checking] && current_user && current_user.name
      flash.now[:alert] = "Please go to #{view_context.link_to("Account page", new_settings_profile_path)} to fill your information".html_safe
    else
      session[:user_name_checking] = true
    end
  end

  def require_contacts
    if !session[:contact_checking] && current_user && (!current_user.uid || !current_user.contact_groups.connected.exists? || current_user.contact_groups.unconnect.exists?)
      flash.now[:alert] = "Please go to #{view_context.link_to("Contacts page", settings_contact_groups_path)} to connect your google account with your toruya groups".html_safe
    else
      session[:contact_checking] = true
    end
  end

  def require_shop
    if !session[:shop_checking] && current_user && !current_user.shops.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Shop page", new_settings_shop_path)} to create your shops".html_safe
    else
      session[:shop_checking] = true
    end
  end

  def require_menu
    if !session[:menu_checking] && current_user && !current_user.menus.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Menu page", new_settings_menu_path)} to create your Menu".html_safe
    else
      session[:menu_checking] = true
    end
  end

  def require_business_hours
    if !session[:business_hours_checking] && current_user && !BusinessSchedule.where(shop_id: current_user.shop_ids).exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Business Schedule page", settings_business_schedules_path)} to set your business schedule".html_safe
    else
      session[:business_hours_checking] = true
    end
  end

  def require_staffs
    if !session[:staffs_checking] && current_user && !current_user.staffs.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Staff page", new_settings_staff_path)} to create your staffs".html_safe
    else
      session[:staffs_checking] = true
    end
  end

  def require_working_times
    if !session[:working_time_checking] && current_user && !BusinessSchedule.where(staff_id: current_user.staff_ids).exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Staff business_schedules page", settings_working_time_staffs_path)} to set their schedules".html_safe
    else
      session[:working_time_checking] = true
    end
  end

  def require_reservation_settings
    if !session[:reservation_settings_checking] && current_user && !current_user.reservation_settings.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Reservation Settings page", new_settings_reservation_setting_path)} to set your reservation settings".html_safe
    else
      session[:reservation_settings_checking] = true
    end
  end
end
