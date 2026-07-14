# frozen_string_literal: true

module Admin
  class SalePagesController < AdminController
    def index
      if compat_read_data_plane?
        @sale_pages = []
        @lookup_user_id = params[:user_id].presence&.to_i
        @lookup_user_id = nil if @lookup_user_id && !@lookup_user_id.positive?
        @lookup_social_service_user_id =
          params[:social_service_user_id].presence if @lookup_user_id.blank?
        return
      end

      user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])&.user || User.find_by(id: params[:user_id])
      @sale_pages = user.sale_pages.order("updated_at DESC")
    end
  end
end
