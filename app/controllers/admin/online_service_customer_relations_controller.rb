# frozen_string_literal: true

module Admin
  class OnlineServiceCustomerRelationsController < AdminController
    def index
      if ENV["COMPAT_API_READ_ENABLED"] == "true"
        @relations = []
        @lookup_user_id = params[:user_id].presence&.to_i
        @lookup_user_id = nil if @lookup_user_id && !@lookup_user_id.positive?
        # Prefer explicit user_id; only fall back to social_service_user_id via AR when needed.
        if @lookup_user_id.blank? && params[:social_service_user_id].present?
          user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])&.user
          @lookup_user_id = user&.id
        end
        return
      end

      user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])&.user || User.find_by(id: params[:user_id])

      @relations = OnlineServiceCustomerRelation
        .includes(:online_service, :sale_page, :customer)
        .where("online_services.user_id": user.id)
        .references(:online_services)
        .order("online_service_customer_relations.id DESC").limit(20)
    end
  end
end
