module Notifications
  class BasicSettingTourPresenter < ::NotificationsPresenter
    def data
      current_step = h.basic_setting_presenter.current_step

      if current_step.present?
        I18n.t("settings.dashboard.basic_tour.notifications.#{current_step}_html",
               url: h.basic_setting_presenter.current_step_setting_path,
               user_name: current_user.name)
      end
    end
  end
end
