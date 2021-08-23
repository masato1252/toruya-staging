# frozen_string_literal: true

class Lines::UserBot::OnlineServiceCustomerRelationsController < Lines::UserBotDashboardController
  def show
    @relation = OnlineServiceCustomerRelation.find(params[:id])

    render layout: false
  end
end
