module AccountRequirement
  extend ActiveSupport::Concern
  ALLOWED_ACCESS_CONTROLLERS = ["settings/menus", "settings/reservation_settings", "settings/working_time/staffs", "settings/staffs", "settings/business_schedules", "settings/shops", "settings/contact_groups", "settings/profiles"].freeze

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
    if is_owner
      if !session[:user_name_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last)
          flash[:alert] = I18n.t("requirement.profile_redirect_message")

          redirect_to new_settings_user_profile_path(super_user)
        end
      elsif !session[:contact_checking]
        # Allow user goes to the path that he already fit the restriction. Otherwise redirect to the proper restriction path.
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(2))
          flash[:alert] = I18n.t("requirement.contact_redirect_message", link: view_context.link_to(I18n.t("requirement.contact_redirect_link_title"), user_google_oauth2_omniauth_authorize_path)).html_safe

          redirect_to settings_user_contact_groups_path(super_user)
        # If user doesn't go to restriction path, go to previous restriction path, just display waring message to remind him.
        elsif except_path("settings/contact_groups")
          flash.now[:alert] = I18n.t("requirement.contact_warning_message", link: view_context.link_to(I18n.t("requirement.contact_warning_link_title"), settings_user_contact_groups_path(super_user))).html_safe
        end
      elsif !session[:shop_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(3))
          flash[:alert] = I18n.t("requirement.shop_redirect_message")

          redirect_to new_settings_user_shop_path(super_user)
        elsif except_path("settings/shops")
          flash.now[:alert] = I18n.t("requirement.shop_warning_message", link: view_context.link_to(I18n.t("requirement.shop_warning_link_title"), new_settings_user_shop_path(super_user))).html_safe
        end
      elsif !session[:business_hours_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(4))
          flash[:alert] = I18n.t("requirement.business_schedule_redirect_message")

          redirect_to settings_user_business_schedules_path(super_user)
        elsif except_path("business_schedules")
          flash.now[:alert] = I18n.t("requirement.business_schedule_warning_message", link: view_context.link_to(I18n.t("requirement.business_schedule_warning_link_title"), settings_user_business_schedules_path(super_user))).html_safe
        end
      elsif !session[:staffs_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(5))
          flash[:alert] = I18n.t("requirement.staff_redirect_message")

          redirect_to new_settings_user_staff_path(super_user)
        elsif except_path("settings/staffs")
          flash.now[:alert] = I18n.t("requirement.staff_warning_message", link: view_context.link_to(I18n.t("requirement.staff_warning_link_title"), new_settings_user_staff_path(super_user))).html_safe
        end
      elsif !session[:working_time_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(6))
          flash[:alert] = I18n.t("requirement.staff_working_schedule_redirect_message")

          redirect_to settings_user_working_time_staffs_path(super_user)
        elsif except_path("settings/working_time/staffs")
          flash.now[:alert] = I18n.t("requirement.staff_working_schedule_warning_message", link: view_context.link_to(I18n.t("requirement.staff_working_schedule_warning_link_title"), settings_user_working_time_staffs_path(super_user))).html_safe
        end
      elsif !session[:reservation_settings_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(7))
          flash[:alert] = I18n.t("requirement.reservation_setting_redirect_message")

          redirect_to new_settings_user_reservation_setting_path(super_user)
        elsif except_path("settings/reservation_settings")
          flash.now[:alert] = I18n.t("requirement.reservation_setting_warning_message", link: view_context.link_to(I18n.t("requirement.reservation_setting_warning_link_title"), new_settings_user_reservation_setting_path(super_user))).html_safe
        end
      elsif !session[:menu_checking]
        if except_path(ALLOWED_ACCESS_CONTROLLERS)
          flash[:alert] = I18n.t("requirement.menu_redirect_message")

          redirect_to new_settings_user_menu_path(super_user)
        elsif except_path("settings/menus")
          flash.now[:alert] = I18n.t("requirement.menu_warning_message", link: view_context.link_to(I18n.t("requirement.menu_warning_link_title"), new_settings_user_menu_path(super_user))).html_safe
        end
      end
    end
  end

  def require_user_name
    if !session[:user_name_checking] && is_owner && super_user.name
      session[:user_name_checking] = true
    end
  end

  def require_contacts
    if !session[:contact_checking] && is_owner && super_user.uid && super_user.contact_groups.connected.exists?
      session[:contact_checking] = true
    end
  end

  def require_shop
    if !session[:shop_checking] && is_owner && super_user.shops.exists?
      session[:shop_checking] = true
    end
  end

  def require_business_hours
    if !session[:business_hours_checking] && is_owner && BusinessSchedule.where(shop_id: super_user.shop_ids).exists?
      session[:business_hours_checking] = true
    end
  end

  def require_staffs
    if !session[:staffs_checking] && is_owner && super_user.staffs.exists?
      session[:staffs_checking] = true
    end
  end

  def require_working_times
    if !session[:working_time_checking] && is_owner && BusinessSchedule.where(staff_id: super_user.staff_ids).exists?
      session[:working_time_checking] = true
    end
  end

  def require_reservation_settings
    if !session[:reservation_settings_checking] && is_owner && super_user.reservation_settings.exists?
      session[:reservation_settings_checking] = true
    end
  end

  def require_menu
    if !session[:menu_checking] && is_owner && super_user.menus.exists?
      session[:menu_checking] = true
    end
  end

  private

  def except_path(controllers)
    !Array(controllers).member?(params[:controller])
  end
end
