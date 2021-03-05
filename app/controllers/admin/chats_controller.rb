# frozen_string_literal: true

module Admin
  class ChatsController < AdminController
    def index
      @selected_social_user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])
    end
  end
end
