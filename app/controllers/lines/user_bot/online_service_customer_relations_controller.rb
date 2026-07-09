# frozen_string_literal: true

class Lines::UserBot::OnlineServiceCustomerRelationsController < Lines::UserBotDashboardController
  def show
    if compat_read_data_plane?
      render :show_compat, layout: false
      return
    end

    @relation = OnlineServiceCustomerRelation.find(params[:id])

    render layout: false
  end
end
