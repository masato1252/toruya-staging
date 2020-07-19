class Users::WebPushSubscriptionsController < DashboardController
  def create
    outcome = WebPushSubscriptions::Create.run!(user: current_user, subscription: params[:subscription].permit!.to_h)

    head :ok
  end
end
