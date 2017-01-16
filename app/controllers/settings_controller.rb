class SettingsController < ActionController::Base
  layout "settings"
  protect_from_forgery with: :exception, prepend: true

  include AccountRequirement
  include ViewHelpers
  include Locale
  include Ssl
end
