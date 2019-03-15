class Settings::WorkingTime::StaffsController < SettingsController
  before_action :set_staff, only: [:update, :working_schedules]
  skip_before_action :authorize_manager_level_permission, only: [:working_schedules, :update]

  def index
    @staffs = if admin?
                Staff.where(user: super_user).undeleted.order(:id)
              else
                Staff.where(user: super_user).undeleted.includes(:staff_account).joins(:shop_relations).where("shop_staffs.shop_id": shop.id)
              end
  end

  def working_schedules
    authorize! :edit, @staff
    flash[:working_time_menu_scope] = params[:working_time_menu_scope]

    if admin?
      @full_time_permission = @regular_working_time_permission = @temporary_working_time_permission = true

      @shops = @staff.shops.order("id")

      if @shops.empty?
        session[:empty_shop_before_setup_working_time] = true
        redirect_to edit_settings_user_staff_path(super_user, @staff)
        return
      end

      @full_time_schedules = @staff.business_schedules.full_time
      @wdays_business_schedules_by_shop = @staff.business_schedules.part_time.order(:day_of_week).group_by(&:shop_id)
      @opened_custom_schedules_by_shop = @staff.custom_schedules.future.opened.order(:start_time).group_by(&:shop_id)
    else
      shop_staff = ShopStaff.find_by(shop: shop, staff: @staff)

      @full_time_permission = can?(:manage_staff_full_time_permission, shop_staff)
      @regular_working_time_permission = can?(:manage_staff_regular_working_day_permission, shop_staff)
      @temporary_working_time_permission = can?(:manage_staff_temporary_working_day_permission, shop_staff)

      @shops = [shop]

      @full_time_schedules = @staff.business_schedules.full_time.where(shop: shop)
      @wdays_business_schedules_by_shop = @staff.business_schedules.part_time.where(shop: shop).order(:day_of_week).group_by(&:shop_id)
      @opened_custom_schedules_by_shop = @staff.custom_schedules.future.opened.where(shop: shop).order(:start_time).group_by(&:shop_id)
    end

    render :edit
  end

  def update
    authorize! :edit, @staff

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

    if custom_schedules_params[:custom_schedules]
      custom_schedules_params[:custom_schedules].each do |attrs|
        CustomSchedules::Change.run(owner: @staff, attrs: attrs.to_h)
      end
    end

    if can?(:manage, Settings)
      if session[:settings_tour]
        redirect_to settings_user_reservation_settings_path(super_user)
      else
        redirect_to settings_user_working_time_staffs_path(super_user, working_time_menu_scope: flash[:working_time_menu_scope]), notice: I18n.t("common.update_successfully_message")
      end
    else
      redirect_to working_schedules_settings_user_working_time_staff_path(super_user, current_user.current_staff(super_user)), notice: I18n.t("common.update_successfully_message")
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
