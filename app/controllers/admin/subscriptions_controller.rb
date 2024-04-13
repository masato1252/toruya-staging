# frozen_string_literal: true

module Admin
  class SubscriptionsController < AdminController
    def destroy
      user = User.find(params[:user_id])
      Subscriptions::Unsubscribe.run!(user: user)

      render json: {
        status: "successful",
        redirect_to: admin_chats_path(user_id: user.id)
      }
    end
  end
end
