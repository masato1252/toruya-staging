class Settings::ProfilesController < SettingsController
  before_action :set_profile, only: [:show, :edit, :update, :destroy]

  def show
    unless @profile
      redirect_to new_settings_profile_path
    end
  end

  def new
    @profile = super_user.build_profile
  end

  def edit
  end

  def create
    @profile = super_user.build_profile(profile_params)

    if @profile.save
      redirect_to settings_profile_path, notice: I18n.t("common.create_successfully_message")
    else
      render :new
    end
  end

  def update
    respond_to do |format|
      if @profile.update(profile_params)
        format.html { redirect_to settings_profile_path, notice: I18n.t("common.update_successfully_message") }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @category.destroy
    respond_to do |format|
      format.html { redirect_to settings_profile_url, notice: I18n.t("common.delete_successfully_message") }
      format.json { head :no_content }
    end
  end

  private

  def set_profile
    @profile = super_user.profile
  end

  def profile_params
    params.require(:profile).permit(:last_name, :first_name, :phonetic_last_name, :phonetic_first_name, :company_name, :zip_code, :address, :website, :phone_number)
  end
end
