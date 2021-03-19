# frozen_string_literal: true

module Tours
  class BasicSettingsPresenter < BasePresenter
    STEPS = {
      customer: {
        warning_view: "welcome"
      },
      shop: {
        warning_view: "shop"
      },
      business_schedule: {
        warning_view: "business_schedule"
      },
      working_time: {
        warning_view: "working_time"
      },
      reservation_setting: {
        warning_view: "reservation_setting"
      },
      menu: {
        warning_view: "menu"
      }
    }

    def title
      I18n.t("settings.dashboard.basic_tour.title")
    end

    def tour_path
      h.settings_tour_path
    end

    def steps
      [
        personal_settings_step,
        customer_settings_step,
        reservation_settings_step
      ]
    end

    def current_step
      return @current_step if defined?(@current_step)

      @current_step = if !customers_settings_completed?
                        :customer
                      elsif !shops_settings_completed?
                        :shop
                      elsif !business_hours_settings_completed?
                        :business_schedule
                      elsif !working_time_settings_completed?
                        :working_time
                      elsif !reservation_settings_completed?
                        :reservation_setting
                      elsif !menu_settings_completed?
                        :menu
                      end
    end

    def current_step_warning
      STEPS[current_step][:warning_view]
    end

    def current_step_setting_path
      case current_step
      when :customer
        h.settings_user_contact_groups_path(user)
      when :shop
        h.new_settings_user_shop_path(user)
      when :business_schedule
        h.settings_user_business_schedules_path(user)
      when :working_time
        h.working_schedules_settings_user_working_time_staff_path(user, user.current_staff(user), working_time_menu_scope: :shop)
      when :reservation_setting
        h.new_settings_user_reservation_setting_path(user)
      when :menu
        h.new_settings_user_menu_path(user)
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

      @customers_settings_completed = user.uid && user.contact_groups.connected.exists?
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

    private

    def personal_settings_step
      Tours::Step.new(
        done: personal_scheduled_enabled?,
        percentage: personal_scheduled_enabled? ? "" : "0%",
        title: I18n.t("settings.dashboard.basic_tour.private_schedule_management"),
        tasks: [
          Tours::Task.new(
            done: profile_settings_completed?,
            title: I18n.t("settings.dashboard.basic_tour.account_info_settings"),
            setting_path: h.settings_profile_path
          )
        ]
      )
    end

    def customer_settings_step
      Tours::Step.new({
        done: customers_management_enabled?,
        percentage: customers_management_enabled? ? "" : "0%",
        title: I18n.t("settings.dashboard.basic_tour.customers_management"),
        tasks: [
          Tours::Task.new(
            done: customers_settings_completed?,
            title: I18n.t("settings.dashboard.basic_tour.customers_settings"),
            setting_path: h.settings_user_contact_groups_path(user)
          )
        ]
      })
    end

    def reservation_settings_step
      Tours::Step.new({
        done: reservation_management_enabled?,
        percentage: h.number_to_percentage(reservation_settings_completed_percentage * 100, precision: 0),
        title: I18n.t("settings.dashboard.basic_tour.reservations_management"),
        tasks: [
          Tours::Task.new(
            done: shops_settings_completed?,
            title: I18n.t("settings.dashboard.basic_tour.shops_settings"),
            setting_path: h.settings_user_shops_path(user),
            setting_path_condition: shops_settings_completed? || customers_settings_completed?
          ),
          Tours::Task.new(
            done: business_hours_settings_completed?,
            title: I18n.t("settings.dashboard.basic_tour.business_hours_settings"),
            setting_path: h.settings_user_business_schedules_path(user),
            setting_path_condition: shops_settings_completed? || business_hours_settings_completed?
          ),
          Tours::Task.new(
            done: working_time_settings_completed?,
            title: I18n.t("settings.dashboard.basic_tour.working_time_settings"),
            setting_path: h.working_schedules_settings_user_working_time_staff_path(user, user.current_staff(user), working_time_menu_scope: :shop),
            setting_path_condition: working_time_settings_completed? || business_hours_settings_completed?
          ),
          Tours::Task.new(
            done: reservation_settings_completed?,
            title: I18n.t("settings.dashboard.basic_tour.reservations_blocks_settings"),
            setting_path: h.settings_user_reservation_settings_path(user),
            setting_path_condition: working_time_settings_completed? || reservation_settings_completed?
          ),
          Tours::Task.new(
            done: menu_settings_completed?,
            title: I18n.t("settings.dashboard.basic_tour.menus_settings"),
            setting_path: h.settings_user_menus_path(user),
            setting_path_condition: menu_settings_completed? || reservation_settings_completed?
          ),
        ]
      })
    end
  end
end
