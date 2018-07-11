class Settings::PaymentsController < SettingsController
  def index
  end

  def create
    debugger
    outcome = Plans::Subscribe.run(
      user: current_user,
      plan: Plan.find_by(level: params[:plan]),
      authorize_token: params[:token],
      upgrade_immediately: params[:upgrade_immediately]
    )

    if outcome.invalid?
      render json: { message: outcome.errors.full_messages.join("") }, status: :unprocessable_entity
    end
  end
end
