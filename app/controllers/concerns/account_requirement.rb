module AccountRequirement
  extend ActiveSupport::Concern
  ALLOWED_ACCESS_CONTROLLERS = ["settings/menus", "settings/reservation_settings", "settings/working_time/staffs", "settings/staffs", "business_schedules", "settings/shops", "settings/contact_groups", "settings/profiles"].freeze

  included do
    before_action :require_user_name
    before_action :require_contacts
    before_action :require_shop
    before_action :require_business_hours
    before_action :require_staffs
    before_action :require_working_times
    before_action :require_reservation_settings
    before_action :require_menu
    before_action :check_requirement
  end

  def check_requirement

    if current_user
      if !session[:user_name_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last)
          flash[:alert] = "Please fill your information"

          redirect_to new_settings_profile_path
        end
      elsif !session[:contact_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(2))
          flash[:alert] = "Please connect your google account with your toruya groups"

          redirect_to settings_contact_groups_path
        elsif except_path("settings/contact_groups")
          flash.now[:alert] = "Please go to #{view_context.link_to("Contacts page", settings_contact_groups_path)} to connect your google account with your toruya groups".html_safe
        end
      elsif !session[:shop_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(3))
          flash[:alert] = "Please create your shops"

          redirect_to new_settings_shop_path
        elsif except_path("settings/shops")
          flash.now[:alert] = "Please go to #{view_context.link_to("Shop page", new_settings_shop_path)} to create your shops".html_safe
        end
      elsif !session[:business_hours_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(4))
          flash[:alert] = "Please set shop business schedules"

          redirect_to settings_business_schedules_path
        elsif except_path("business_schedules")
          flash.now[:alert] = "Please go to #{view_context.link_to("Business Schedule page", settings_business_schedules_path)} to set your business schedule".html_safe
        end
      elsif !session[:staffs_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(5))
          flash[:alert] = "Please create your staffs"

          redirect_to new_settings_staff_path
        elsif except_path("settings/staffs")
          flash.now[:alert] = "Please go to #{view_context.link_to("Staff page", new_settings_staff_path)} to create your staffs".html_safe
        end
      elsif !session[:working_time_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(6))
          flash[:alert] = "Please set their schedules"

          redirect_to settings_working_time_staffs_path
        elsif except_path("settings/working_time/staffs")
          flash.now[:alert] = "Please go to #{view_context.link_to("Staff business_schedules page", settings_working_time_staffs_path)} to set their schedules".html_safe
        end
      elsif !session[:reservation_settings_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(7))
          flash[:alert] = "Please set your reservation settings"

          redirect_to new_settings_reservation_setting_path
        elsif except_path("settings/reservation_settings")
          flash.now[:alert] = "Please go to #{view_context.link_to("Reservation Settings page", new_settings_reservation_setting_path)} to set your reservation settings".html_safe
        end
      elsif !session[:menu_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS)
          flash[:alert] = "Please create your Menu"

          redirect_to new_settings_menu_path
        elsif except_path("settings/menus")
          flash.now[:alert] = "Please go to #{view_context.link_to("Menu page", new_settings_menu_path)} to create your Menu".html_safe
        end
      end
    end
  end

  def require_user_name
    if !session[:user_name_checking] && current_user && current_user.name
      session[:user_name_checking] = true
    end
  end

  def require_contacts
    if !session[:contact_checking] && current_user && current_user.uid && current_user.contact_groups.connected.exists?
      session[:contact_checking] = true
    end
  end

  def require_shop
    if !session[:shop_checking] && current_user && current_user.shops.exists?
      session[:shop_checking] = true
    end
  end

  def require_business_hours
    if !session[:business_hours_checking] && current_user && BusinessSchedule.where(shop_id: current_user.shop_ids).exists?
      session[:business_hours_checking] = true
    end
  end

  def require_staffs
    if !session[:staffs_checking] && current_user && current_user.staffs.exists?
      session[:staffs_checking] = true
    end
  end

  def require_working_times
    if !session[:working_time_checking] && current_user && BusinessSchedule.where(staff_id: current_user.staff_ids).exists?
      session[:working_time_checking] = true
    end
  end

  def require_reservation_settings
    if !session[:reservation_settings_checking] && current_user && current_user.reservation_settings.exists?
      session[:reservation_settings_checking] = true
    end
  end

  def require_menu
    if !session[:menu_checking] && current_user && current_user.menus.exists?
      session[:menu_checking] = true
    end
  end

  private

  def except_path(controllers)
    !Array(controllers).member?(params[:controller])
  end
end
