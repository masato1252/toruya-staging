module Notifications
  class BasicSettingTourPresenter < ::NotificationsPresenter
    def data
      current_step = h.basic_setting_presenter.current_step

      if current_step.present?
        uri = URI.parse(h.basic_setting_presenter.current_step_setting_path)
        query = Rack::Utils.parse_query(uri.query)
        query["enable_tour_warning"] = true
        uri.query = Rack::Utils.build_query(query)

        I18n.t("settings.dashboard.basic_tour.notifications.#{current_step}_html",
               url: uri.to_s,
               user_name: current_user.name,
               hide_warning_url: h.settings_hide_tour_warning_path)
      end
    end
  end
end
