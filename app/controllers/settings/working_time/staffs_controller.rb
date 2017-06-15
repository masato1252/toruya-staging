class Settings::WorkingTime::StaffsController < SettingsController
  before_action :set_staff, only: [:update, :working_schedules, :holiday_schedules]
  skip_before_action :admin_required, only: [:working_schedules, :holiday_schedules, :update]

  def index
    @staffs = super_user.staffs.active.order("id")
  end

  def working_schedules
    @mode = "working_schedules"
    @staff = super_user.staffs.find_by(id: params[:id])
    @full_time_schedules = @staff.business_schedules.full_time
    @wdays_business_schedules_by_shop = @staff.business_schedules.order(:day_of_week).group_by(&:shop_id)
    @opened_custom_schedules_by_shop = @staff.custom_schedules.future.opened.order(:start_time).group_by(&:shop_id)

    render :edit
  end

  def holiday_schedules
    @mode = "holiday_schedules"
    @closed_custom_schedules = @staff.custom_schedules.future.closed.order(:start_time)
    render :edit
  end

  def update
    if params[:business_schedules]
      params.permit![:business_schedules].each do |shop_id, attrs|
        if attrs[:full_time]
          BusinessSchedules::Create.run(shop: Shop.find(shop_id), staff: @staff, attrs: attrs.to_h)
        elsif attrs.except(:id).blank?
          # Select part time and don't set any routine wday schedules.
          BusinessSchedule.where(shop_id: shop_id, staff_id: @staff.id, full_time: true).destroy_all
        else
          attrs.except(:id).each do |humanize_wday, attr|
            BusinessSchedules::Create.run(shop: Shop.find(shop_id), staff: @staff, attrs: attr.to_h)
          end
        end
      end
    end

    custom_schedules_params[:custom_schedules].each do |attrs|
      CustomSchedules::Create.run(staff: @staff, attrs: attrs.to_h)
    end if custom_schedules_params[:custom_schedules]

    if can?(:manage, Settings)
      redirect_to settings_user_working_time_staffs_path(super_user), notice: I18n.t("common.update_successfully_message")
    elsif params[:business_schedules]
      redirect_to working_schedules_settings_user_working_time_staff_path(super_user, current_user.current_staff(super_user)), notice: I18n.t("common.update_successfully_message")
    else
      redirect_to holiday_schedules_settings_user_working_time_staff_path(super_user, current_user.current_staff(super_user)), notice: I18n.t("common.update_successfully_message")
    end
  end

  private

  def set_staff
    @staff = super_user.staffs.find_by(id: params[:id])
    redirect_to settings_user_staffs_path(super_user, shop) unless @staff
  end

  def custom_schedules_params
    params.permit(custom_schedules: [:id, :shop_id, :start_time_date_part, :start_time_time_part, :end_time_time_part, :reason, :_destroy, :open])
  end
end
