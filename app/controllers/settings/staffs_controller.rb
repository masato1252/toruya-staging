class Settings::StaffsController < SettingsController
  before_action :set_staff, only: [:show, :edit, :update, :destroy, :resend_activation_email]
  skip_before_action :authorize_manager_level_permission, only: [:edit, :update]

  # GET /staffs
  # GET /staffs.json
  def index
    @staffs = if admin?
                Staff.where(user: super_user).undeleted.order(:id)
              else
                Staff.where(user: super_user).undeleted.includes(:staff_account).joins(:shop_relations).where("shop_staffs.shop_id": shop.id).order("id")
              end
  end

  # GET /staffs/1
  # GET /staffs/1.json
  def show
  end

  # GET /staffs/new
  def new
    authorize! :create, Staff

    @staff = super_user.staffs.new
    @staff_account = staff.build_staff_account(owner: super_user, level: :employee)
  end

  # GET /staffs/1/edit
  def edit
    authorize! :edit, @staff

    @staff_account = super_user.owner_staff_accounts.find_by(staff: @staff)
    if @staff.active? && (profile = @staff_account.user.profile)
      @staff.first_name = @staff.first_name.presence || profile.first_name
      @staff.last_name = @staff.last_name.presence || profile.last_name
      @staff.phonetic_first_name = @staff.phonetic_first_name.presence || profile.phonetic_first_name
      @staff.phonetic_last_name = @staff.phonetic_last_name.presence || profile.phonetic_last_name
    end
  end

  # POST /staffs
  # POST /staffs.json
  def create
    authorize! :create, Staff

    staff_outcome = Staffs::Create.run(user: super_user, attrs: params[:staff]&.permit!&.to_h)
    staff = staff_outcome.result

    StaffAccounts::Create.run(staff: staff, owner: staff.user, params: params[:staff_account].permit!.to_h)

    params.permit![:shop_staff].each do |shop_id, attrs|
      staff.shop_relations.where(shop_id: shop_id).update(attrs.to_h)
    end if params[:shop_staff]

    if staff_outcome.valid?
      redirect_to settings_user_staffs_path(super_user), notice: I18n.t("settings.staff_account.sent_message")
    else
      render :new
    end
  end

  # PATCH/PUT /staffs/1
  # PATCH/PUT /staffs/1.json
  def update
    authorize! :edit, @staff

    outcome = Staffs::Update.run(is_manager: manager?,
                                 staff: @staff,
                                 attrs: params[:staff]&.permit!&.to_h)

    staff_account_outcome = StaffAccounts::Create.run(staff: @staff, owner: @staff.user, params: params[:staff_account].permit!.to_h) if params[:staff_account]

    params.permit![:shop_staff].each do |shop_id, attrs|
      @staff.shop_relations.where(shop_id: shop_id).update(attrs.to_h)
    end if params[:shop_staff]

    if outcome.valid? && (staff_account_outcome ? staff_account_outcome.valid? : true)
      if session[:empty_shop_before_setup_working_time]
        session[:empty_shop_before_setup_working_time] = nil
        redirect_to working_schedules_settings_user_working_time_staff_path(super_user, @staff)
        return
      end

      if ability(super_user, shop).can?(:manage, Settings)
        redirect_to settings_user_staffs_path(super_user), notice: I18n.t("common.update_successfully_message")
      else
        redirect_to edit_settings_user_staff_path(super_user, @staff), notice: I18n.t("common.update_successfully_message")
      end
    else
      redirect_to edit_settings_user_staff_path(super_user, @staff), alert: outcome.errors.full_messages.first || staff_account_outcome.errors.full_messages.first
    end
  end

  # DELETE /staffs/1
  # DELETE /staffs/1.json
  def destroy
    authorize! :delete, Staff
    outcome = Staffs::Delete.run(staff: @staff)

    if outcome.valid?
      redirect_to settings_user_staffs_path(super_user), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to settings_user_staffs_path(super_user)
    end
  end

  def resend_activation_email
    outcome = StaffAccounts::Create.run(staff: @staff, owner: @staff.user, resend: true, params: { email: params[:email], level: params[:level] })

    if outcome.valid?
      flash[:notice] = I18n.t("settings.staff_account.sent_message")
      head :ok
    else
      render json: { message: outcome.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def set_staff
    @staff = Staff.find_by(id: params[:id], user_id: super_user.id)
    redirect_to settings_user_staffs_path(super_user, shop) unless @staff
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def staff_params
    params.require(:staff).permit(:first_name, :last_name, :phonetic_first_name, :phonetic_last_name, shop_ids: [])
  end
end
