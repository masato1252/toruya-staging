# frozen_string_literal: true

module Admin
  class SalePagesController < AdminController
    def index
      user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])&.user || User.find_by(id: params[:user_id])

      if ENV["COMPAT_API_READ_ENABLED"] == "true"
        @sale_pages = []
        @lookup_user_id = user&.id
        return
      end

      @sale_pages = user.sale_pages.order("updated_at DESC")
    end
  end
end
