# frozen_string_literal: true

module Admin
  class BookingPagesController < AdminController
    def index
      user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])&.user || User.find_by(id: params[:user_id])

      @booking_pages = user.booking_pages.order("updated_at DESC")
    end
  end
end
