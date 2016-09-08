class Settings::WorkingTime::StaffsController < SettingsController
  before_action :set_staff, only: [:edit, :update]

  def index
    @staffs = super_user.staffs
  end

  def edit
    @staff = super_user.staffs.find_by(id: params[:id])
    @full_time_schedules = @staff.business_schedules.full_time
    @wdays_business_schedules_by_shop = @staff.business_schedules.order(:day_of_week).group_by(&:shop_id)
  end

  def update
    params.permit![:business_schedules].each do |shop_id, attrs|
      if attrs[:full_time]
        CreateBusinessSchedule.run(shop: Shop.find(shop_id), staff: @staff, attrs: attrs.to_h)
      else
        attrs.except(:id).each do |humanize_wday, attr|
          CreateBusinessSchedule.run(shop: Shop.find(shop_id), staff: @staff, attrs: attr.to_h)
        end
      end
    end

    redirect_to settings_working_time_staffs_path
  end

  private

  def set_staff
    @staff = super_user.staffs.find_by(id: params[:id])
    redirect_to settings_staffs_path(shop) unless @staff
  end
end
