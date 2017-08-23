class SettingsController < ActionController::Base
  layout "settings"
  protect_from_forgery with: :exception, prepend: true

  include AccountRequirement
  include ViewHelpers
  include Locale
  include Ssl

  before_action :manager_required

  def manager_required
    unless current_ability.can?(:manage, Settings)
      redirect_to root_path, alert: "Need permission."
    end
  end
end
