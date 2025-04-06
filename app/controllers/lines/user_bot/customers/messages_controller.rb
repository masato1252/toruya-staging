# frozen_string_literal: true

class Lines::UserBot::Customers::MessagesController < Lines::UserBotDashboardController
  before_action :set_customer, only: [:index]

  def index
    render json: SocialMessages::Recent.run!(
      customer: @customer,
      oldest_message_at: params[:oldest_message_at],
      oldest_message_id: params[:oldest_message_id]
    )
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end
end
