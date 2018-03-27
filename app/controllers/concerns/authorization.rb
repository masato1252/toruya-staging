module Authorization
  extend ActiveSupport::Concern

  included do
    protect_from_forgery prepend: true, with: :exception
    before_action :authenticate_user!
  end
end
