# frozen_string_literal: true

class Lines::UserBot::Settings::StripesController < Lines::UserBotDashboardController
  before_action :load_compat_stripe_provider, only: [:show]

  def show
    if compat_read_data_plane?
      render :show_compat
      return
    end
  end

  def update
    if compat_read_data_plane?
      result = compat_v1_put("/lines/user_bot/owner/#{business_owner_id}/settings/stripe", {})
      redirect_path = lines_user_bot_settings_path(business_owner_id: business_owner_id)

      if result&.dig("status") == "successful"
        redirect_to redirect_path, notice: t("common.update_successfully_message")
      else
        message = result&.dig("error_message").presence || t("common.update_failed_message")
        redirect_to redirect_path, alert: message
      end
      return
    end

    AccessProviders::SetDefaultPayment.run!(access_provider: Current.business_owner.stripe_provider)
    redirect_to lines_user_bot_settings_path(business_owner_id: business_owner_id), notice: t("common.update_successfully_message")
  end

  private

  def load_compat_stripe_provider
    return unless compat_read_data_plane?

    body = compat_fetch_v1_json("/lines/user_bot/owner/#{business_owner_id}/settings/stripe/page_context")
    form = body&.dig("data", "edit_form") || {}
    @stripe_connected = form["connected"]
    @stripe_default_payment = form["default_payment"]
  end
end
