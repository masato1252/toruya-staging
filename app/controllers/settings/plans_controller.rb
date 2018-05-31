class Settings::PlansController < SettingsController
  def index
  end

  def create
    outcome = Plans::Subscribe.run(user: current_user, plan: Plan.find_by(level: :free), authorize_token: params[:token])

    if outcome.valid?
      head(:ok)
    else
      render json: { message: outcome.errors.full_messages.join("") }, status: :unprocessable_entity
    end
  end
end
