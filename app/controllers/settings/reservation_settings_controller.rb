class Settings::ReservationSettingsController < SettingsController
  before_action :set_reservation_setting, only: [:edit, :update, :destroy]

  def index
    @reservation_settings = super_user.reservation_settings
  end

  def new
    @reservation_setting = super_user.reservation_settings.new
  end

  def create
    @reservation_setting = super_user.reservation_settings.new(reservation_setting_params)
    if @reservation_setting.save
      redirect_to settings_reservation_settings_path
    else
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @reservation_setting.update(reservation_setting_params)
        format.html { redirect_to settings_reservation_settings_path, notice: 'Menu was successfully updated.' }
        format.json { render :show, status: :ok, location: @menu }
      else
        format.html { render :edit }
        format.json { render json: @settings_menu.errors, status: :unprocessable_entity }
      end
    end
  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_reservation_setting
    @reservation_setting = super_user.reservation_settings.find(params[:id])
  end

  def reservation_setting_params
    params.require(:reservation_setting).permit(
      :id, :name, :short_name, :day_type,
      :day, :nth_of_week, :start_time, :end_time, days_of_week: []
    )
  end
end
