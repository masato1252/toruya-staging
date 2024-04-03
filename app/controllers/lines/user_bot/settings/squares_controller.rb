# frozen_string_literal: true

class Lines::UserBot::Settings::SquaresController < Lines::UserBotDashboardController
  def show
  end

  def update
    AccessProviders::SetDefaultPayment.run!(access_provider: Current.business_owner.square_provider)
    redirect_to lines_user_bot_settings_path(business_owner_id: business_owner_id), notice: t("common.update_successfully_message")
  end
end
