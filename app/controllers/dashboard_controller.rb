class DashboardController < ActionController::Base
  abstract!

  layout "application"
  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry

  before_action :profile_required
  before_action :set_paper_trail_whodunnit
  before_action :sync_user

  private

  def profile_required
    unless current_user.profile
      # default is stay in personal dashboard
      cookies[:dashboard_mode] = "user"
      redirect_to new_profile_path
    end
  end

  def contact_group_required
    redirect_to settings_dashboard_path unless BasicSettingsPresenter.new(view_context, super_user).customers_settings_completed?
  end

  def sync_user
    Users::ContactsSync.run!(user: super_user) if super_user
  end

  def repair_nested_params(obj = params)
    obj.each do |key, value|
      if value.is_a?(ActionController::Parameters) || value.is_a?(Hash)
        # If any non-integer keys
        if value.keys.find {|k, _| k =~ /\D/ }
          repair_nested_params(value)
        else
          obj[key] = value.values
          value.values.each {|h| repair_nested_params(h) }
        end
      end
    end
  end
end
