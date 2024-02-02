# frozen_string_literal: true

class Lines::UserBot::Reservations::MessagesController < Lines::UserBotDashboardController
  before_action :authorize_reservation

  def new
  end

  def create
    broadcast_params = {
      content: params[:content],
      query: {
        "filters" => [{
          "field" => "reservation_id",
          "value" => reservation.id,
          "condition" => "eq"
        }],
        "operator" => "or"
      },
      query_type: "reservation_customers"
    }

    outcome = Broadcasts::Create.run(user: Current.business_owner, params: broadcast_params)

    flash[:success] = "Broadcast create successfully"
    return_json_response(outcome, { redirect_to: lines_user_bot_schedules_path(business_owner_id: reservation.user_id, reservation_id: reservation.id) })
  end


  private

  def reservation
    @reservation ||= Reservation.find(params[:reservation_id])
  end

  def authorize_reservation
    authorize! :edit, reservation
  end
end
