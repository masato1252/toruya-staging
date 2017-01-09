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
      if params[:from_menu]
        if params[:menu_id]
          redirect_to edit_settings_menu_path(id: params[:menu_id]), notice: I18n.t("common.create_successfully_message")
        else
          redirect_to new_settings_menu_path(reservation_setting_id: @reservation_setting.id), notice: I18n.t("common.create_successfully_message")
        end
      else
        redirect_to settings_reservation_settings_path, notice: I18n.t("common.create_successfully_message")
      end
    else
    end
  end

  def edit
  end

  def update
    if @reservation_setting.update(reservation_setting_params.reverse_merge(day: nil, nth_of_week: nil, days_of_week: nil))
      if params[:from_menu]
        if params[:menu_id]
          redirect_to edit_settings_menu_path(id: params[:menu_id]), notice: I18n.t("common.update_successfully_message")
        else
          redirect_to new_settings_menu_path(reservation_setting_id: @reservation_setting.id), notice: I18n.t("common.update_successfully_message")
        end
      else
        redirect_to settings_reservation_settings_path, notice: I18n.t("common.update_successfully_message")
      end
    else
      render :edit
    end
  end

  def destroy
    @reservation_setting.destroy
    redirect_to settings_reservation_settings_path
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
