class Settings::ProfilesController < SettingsController
  before_action :set_profile, only: [:show, :edit, :update, :destroy]

  def show
    unless @profile
      redirect_to new_profile_path
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @profile.update(profile_params)
        format.html { redirect_to settings_user_profile_path(super_user), notice: I18n.t("common.update_successfully_message") }
      else
        format.html { render :edit }
      end
    end
  end

  private

  def set_profile
    @profile = super_user.profile
  end

  def profile_params
    params.require(:profile).permit(:last_name, :first_name, :phonetic_last_name, :phonetic_first_name, :company_name, :zip_code, :address, :website, :phone_number, :company_zip_code, :company_address, :company_phone_number)
  end
end
