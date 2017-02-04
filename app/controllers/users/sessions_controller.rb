class Users::SessionsController < Devise::SessionsController
  prepend_before_action :verify_user, only: [:destroy]

  private
  # This method intercepts SessionsController#destroy action
  # When user sign out and sign in another tab, and sign in again that casue its session is different.
  # http://stackoverflow.com/q/22487290/609365
  def verify_user
    redirect_to root_path unless verified_request?
  end
end
