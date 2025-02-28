# frozen_string_literal: true

class Lines::UserBot::Settings::ProfilesController < Lines::UserBotDashboardController
  def show
    @profile = Current.business_owner.profile
  end

  def company
    @profile = Current.business_owner.profile
  end

  def edit
    @profile = Current.business_owner.profile
    @previous_path =
      case params[:attribute]
      when "name"
        lines_user_bot_settings_profile_path(business_owner_id: params[:business_owner_id])
      when "company_name", "company_phone_number", "website", "company_address_details", "logo"
        company_lines_user_bot_settings_profile_path(business_owner_id: params[:business_owner_id])
      end
    @title =
      case params[:attribute]
      when "name"
        I18n.t("settings.profile.user_info")
      when "company_name", "company_phone_number", "website", "company_address_details", "logo"
        I18n.t("settings.profile.company_info")
      end
  end

  def update
    outcome = Profiles::UpdateAttribute.run(profile: Current.business_owner.profile, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    redirect_path =
      case params[:attribute]
      when "name"
        lines_user_bot_settings_profile_path(business_owner_id: params[:business_owner_id])
      when "company_name", "company_phone_number", "website", "company_address_details", 'logo', "company_email"
        company_lines_user_bot_settings_profile_path(business_owner_id: params[:business_owner_id])
      end

    return_json_response(outcome, { redirect_to: redirect_path })
  end
end
