module Authorization
  extend ActiveSupport::Concern

  included do
    protect_from_forgery prepend: true, with: :exception
    before_action :authenticate_user!
    before_action :authenticate_shop_permission!
  end

  def authenticate_shop_permission!
    authorize! :read, shop
  end
end
