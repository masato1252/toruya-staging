class Users::ChatsController < DashboardController
  def index
    social_accounts = super_user.social_accounts

    @selected_social_customer = super_user.social_customers.find_by(social_user_id: params[:customer_id])

    if @selected_social_customer
      @selected_social_account = @selected_social_customer.social_account
    else
      @selected_social_account = social_accounts.first
    end
  end
end
