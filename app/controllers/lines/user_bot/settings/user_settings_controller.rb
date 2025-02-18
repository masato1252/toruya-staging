# frozen_string_literal: true

class Lines::UserBot::Settings::UserSettingsController < Lines::UserBotDashboardController
  def edit
  end

  def update
    outcome = ::UserSettings::Update.run(user_setting: Current.business_owner.user_setting, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    flash[:notice] = I18n.t("common.update_successfully_message")

    return_json_response(outcome, { redirect_to: params[:back_path] || lines_user_bot_customers_path(business_owner_id: business_owner_id) })
  end
end