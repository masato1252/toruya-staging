# frozen_string_literal: true

module Admin
  class SalePagesController < AdminController
    def index
      user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])&.user || User.find_by(id: params[:user_id])

      @sale_pages = user.sale_pages.order("updated_at DESC")
    end
  end
end
