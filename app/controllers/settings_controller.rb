class SettingsController < ActionController::Base
  layout "settings"

  include AccountRequirement
  include ViewHelpers
  include Locale
end
