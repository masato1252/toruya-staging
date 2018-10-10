class Users::ProfilesController < DashboardController
  before_action :profile_checking
  skip_before_action :profile_required
  layout "home"

  def new
    @profile = current_user.build_profile
  end

  def create
    @profile = current_user.build_profile(profile_params)

    if @profile.save
      if params[:from_staff_account].present?
        redirect_to member_path
      else
        redirect_to settings_dashboard_path, notice: I18n.t("common.create_successfully_message")
      end
    else
      render :new
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:last_name, :first_name, :phonetic_last_name, :phonetic_first_name, :company_name, :zip_code, :address, :website, :phone_number, :company_zip_code, :company_address, :company_phone_number)
  end

  def profile_checking
    redirect_to settings_dashboard_path if current_user.profile
  end
end
