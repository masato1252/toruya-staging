# frozen_string_literal: true

class Lines::UserBot::Settings::StripesController < Lines::UserBotDashboardController
  def show
    if compat_read_data_plane?
      render :show_compat
      return
    end
  end

  def update
    AccessProviders::SetDefaultPayment.run!(access_provider: Current.business_owner.stripe_provider)
    redirect_to lines_user_bot_settings_path(business_owner_id: business_owner_id), notice: t("common.update_successfully_message")
  end
end
