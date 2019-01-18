class Users::ProfilesController < DashboardController
  before_action :profile_checking
  skip_before_action :profile_required
  layout "home"

  def new
    @profile = current_user.build_profile
  end

  def create
    outcome = Profiles::Create.run(user: current_user, params: profile_params)

    if outcome.valid?
      if params[:from_staff_account].present?
        redirect_to member_path
      else
        redirect_to settings_dashboard_path, notice: I18n.t("common.create_successfully_message")
      end
    else
      @profile = current_user.build_profile(profile_params)
      @profile.valid?
      render :new
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:last_name, :first_name, :phonetic_last_name, :phonetic_first_name, :address, :phone_number, :zip_code)
  end

  def profile_checking
    redirect_to settings_dashboard_path if current_user.profile
  end
end
