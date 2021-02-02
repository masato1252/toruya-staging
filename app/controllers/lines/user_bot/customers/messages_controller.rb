# frozen_string_literal: true

class Lines::UserBot::Customers::MessagesController < Lines::UserBotDashboardController
  before_action :set_customer, only: [:index]

  def index
    unless @customer.social_customer
      render json: { messages: [] }
      return
    end

    social_messages = SocialMessages::Recent.run!(customer: @customer)

    render json: { messages: social_messages }
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end
end
