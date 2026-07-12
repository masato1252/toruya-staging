# frozen_string_literal: true

module Admin
  class BookingPagesController < AdminController
    def index
      if compat_read_data_plane?
        @booking_pages = []
        @lookup_user_id = params[:user_id].presence&.to_i
        @lookup_user_id = nil if @lookup_user_id && !@lookup_user_id.positive?
        if @lookup_user_id.blank? && params[:social_service_user_id].present?
          user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])&.user
          @lookup_user_id = user&.id
        end
        return
      end

      user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])&.user || User.find_by(id: params[:user_id])
      @booking_pages = user.booking_pages.order("updated_at DESC")
    end
  end
end
