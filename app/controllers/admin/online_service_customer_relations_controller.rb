# frozen_string_literal: true

module Admin
  class OnlineServiceCustomerRelationsController < AdminController
    def index
      user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])&.user || User.find_by(id: params[:user_id])

      @relations = OnlineServiceCustomerRelation.
        includes(:online_service, :sale_page, :customer).
        where("online_services.user_id": user.id).
        references(:online_services).
        order("online_service_customer_relations.id DESC").limit(20)
    end
  end
end
