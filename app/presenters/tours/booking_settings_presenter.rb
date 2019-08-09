module Tours
  class BookingSettingsPresenter < BasePresenter
    ALLOWED_ACCESS_CONTROLLERS = ["settings/shops", "settings/booking_options", "settings/booking_pages"].freeze

    attr_reader :user, :h

    def title
      I18n.t("settings.dashboard.booking_tour.title")
    end

    def tour_path
      h.settings_booking_tour_path
    end

    def steps
      [
        shop_logo_settings_step,
        booking_option_settings_step,
        booking_page_settings_step
      ]
    end

    def completed?
      shop_logo_setup? && booking_option_setup? && booking_page_setup?
    end

    def booking_option_setup?
      return @booking_option_setup if defined?(@booking_option_setup)

      @booking_option_setup  = user.booking_options.exists?
    end

    private

    def shop_logo_settings_step
      Tours::Step.new({
        done: shop_logo_setup?,
        percentage: shop_logo_setup? ? "" : "0%",
        title: I18n.t("settings.dashboard.booking_tour.shop_logo_setup"),
        tasks: [
          Tours::Task.new(
            done: shop_logo_setup?,
            title: I18n.t("settings.dashboard.booking_tour.shop_logo_setup"),
            setting_path: h.settings_user_shops_path(user),
            accessable_controller_in_tour: ALLOWED_ACCESS_CONTROLLERS.first(1)
          )
        ]
      })
    end

    def shop_logo_setup?
      return @shop_logo_setup if defined?(@shop_logo_setup)

      @shop_logo_setup = user.shops.any? { |s| s.logo.attached? }
    end

    def booking_option_settings_step
      Tours::Step.new({
        done: booking_option_setup?,
        percentage: booking_option_setup? ? "" : "0%",
        title: I18n.t("settings.dashboard.booking_tour.booking_option_setup"),
        tasks: [
          Tours::Task.new(
            done: booking_option_setup?,
            title: I18n.t("settings.dashboard.booking_tour.booking_option_setup"),
            setting_path: h.settings_user_booking_options_path(user),
            setting_path_condition: shop_logo_setup? || booking_option_setup?,
            accessable_controller_in_tour: ALLOWED_ACCESS_CONTROLLERS.first(2)
          )
        ]
      })
    end

    def booking_page_settings_step
      Tours::Step.new({
        done: booking_page_setup?,
        percentage: booking_page_setup? ? "" : "0%",
        title: I18n.t("settings.dashboard.booking_tour.booking_page_setup"),
        tasks: [
          Tours::Task.new(
            done: booking_page_setup?,
            title: I18n.t("settings.dashboard.booking_tour.booking_page_setup"),
            setting_path: h.settings_user_booking_pages_path(user),
            setting_path_condition: (shop_logo_setup? && booking_option_setup?) || booking_page_setup?,
            accessable_controller_in_tour: ALLOWED_ACCESS_CONTROLLERS.first(3)
          )
        ]
      })
    end

    def booking_page_setup?
      return @booking_page_setup if defined?(@booking_page_setup)

      @booking_page_setup = user.booking_pages.exists?
    end
  end
end
