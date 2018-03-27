module Authorization
  extend ActiveSupport::Concern

  included do
    protect_from_forgery prepend: true, with: :exception
    before_action :authenticate_user!
    before_action :authenticate_super_user
  end

  def authenticate_super_user
    if current_user != super_user && current_user.current_staff(super_user).nil?
      redirect_to member_path, alert: "No permission"
    end
  end
  end
end
