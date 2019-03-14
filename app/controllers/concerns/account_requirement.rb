module AccountRequirement
  extend ActiveSupport::Concern
  ALLOWED_ACCESS_CONTROLLERS = ["settings/menus", "settings/reservation_settings", "settings/working_time/staffs", "settings/business_schedules", "settings/shops", "settings/contact_groups"].freeze
  IGNORE_CONTROLLERS = ["settings/profiles", "settings/plans", "settings/payments"].freeze

  included do
    before_action :check_requirement
  end

  def check_requirement
    if is_owner
      return unless session[:settings_tour]

      if !basic_setting_presenter.customers_settings_completed?
        # Allow user goes to the path that he already fit the restriction. Otherwise redirect to the proper restriction path.
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(1) + IGNORE_CONTROLLERS)
          flash[:alert] = I18n.t("requirement.contact_redirect_message").html_safe

          redirect_to settings_user_contact_groups_path(super_user)
        # If user doesn't go to restriction path, go to previous restriction path, just display waring message to remind him.
        elsif except_path("settings/contact_groups")
          flash.now[:alert] = I18n.t("requirement.contact_warning_message", link: view_context.link_to(I18n.t("requirement.contact_warning_link_title"), settings_user_contact_groups_path(super_user))).html_safe
        end
      elsif !basic_setting_presenter.shops_settings_completed?
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(2) + IGNORE_CONTROLLERS)
          flash[:alert] = I18n.t("requirement.shop_redirect_message")

          redirect_to new_settings_user_shop_path(super_user)
        elsif except_path("settings/shops")
          flash.now[:alert] = I18n.t("requirement.shop_warning_message", link: view_context.link_to(I18n.t("requirement.shop_warning_link_title"), new_settings_user_shop_path(super_user))).html_safe
        end
      elsif !basic_setting_presenter.business_hours_settings_completed?
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(3) + IGNORE_CONTROLLERS)
          flash[:alert] = I18n.t("requirement.business_schedule_redirect_message")

          redirect_to settings_user_business_schedules_path(super_user)
        elsif except_path("business_schedules")
          flash.now[:alert] = I18n.t("requirement.business_schedule_warning_message", link: view_context.link_to(I18n.t("requirement.business_schedule_warning_link_title"), settings_user_business_schedules_path(super_user))).html_safe
        end
      elsif !basic_setting_presenter.working_time_settings_completed?
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(4) + IGNORE_CONTROLLERS)
          flash[:alert] = I18n.t("requirement.staff_working_schedule_redirect_message")

          redirect_to settings_user_working_time_staffs_path(super_user)
        elsif except_path("settings/working_time/staffs")
          flash.now[:alert] = I18n.t("requirement.staff_working_schedule_warning_message", link: view_context.link_to(I18n.t("requirement.staff_working_schedule_warning_link_title"), settings_user_working_time_staffs_path(super_user))).html_safe
        end
      elsif !basic_setting_presenter.reservation_settings_completed?
        if except_path(ALLOWED_ACCESS_CONTROLLERS.last(5) + IGNORE_CONTROLLERS)
          flash[:alert] = I18n.t("requirement.reservation_setting_redirect_message")

          redirect_to new_settings_user_reservation_setting_path(super_user)
        elsif except_path("settings/reservation_settings")
          flash.now[:alert] = I18n.t("requirement.reservation_setting_warning_message", link: view_context.link_to(I18n.t("requirement.reservation_setting_warning_link_title"), new_settings_user_reservation_setting_path(super_user))).html_safe
        end
      elsif !basic_setting_presenter.menu_settings_completed?
        if except_path(ALLOWED_ACCESS_CONTROLLERS + IGNORE_CONTROLLERS)
          flash[:alert] = I18n.t("requirement.menu_redirect_message")

          redirect_to new_settings_user_menu_path(super_user)
        elsif except_path("settings/menus")
          flash.now[:alert] = I18n.t("requirement.menu_warning_message", link: view_context.link_to(I18n.t("requirement.menu_warning_link_title"), new_settings_user_menu_path(super_user))).html_safe
        end
      end
    end
  end

  private

  def except_path(controllers)
    !expect_path(controllers)
  end

  def expect_path(controllers)
    Array(controllers).member?(params[:controller])
  end
end
