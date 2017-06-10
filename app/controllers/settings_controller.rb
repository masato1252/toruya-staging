class SettingsController < ActionController::Base
  layout "settings"
  protect_from_forgery with: :exception, prepend: true

  include AccountRequirement
  include ViewHelpers
  include Locale
  include Ssl

  before_action :admin_required

  def admin_required
    unless current_ability.can?(:manage, Settings)
      redirect_to root_path, alert: "Need admin permission."
    end
  end
end
