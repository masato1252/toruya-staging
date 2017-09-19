class Settings::StaffsController < SettingsController
  before_action :set_staff, only: [:show, :edit, :update, :destroy]
  skip_before_action :authorize_manager_level_permission, only: [:edit, :update]

  # GET /staffs
  # GET /staffs.json
  def index
  end

  # GET /staffs/1
  # GET /staffs/1.json
  def show
  end

  # GET /staffs/new
  def new
    @staff = super_user.staffs.new
  end

  # GET /staffs/1/edit
  def edit
    @staff_account = super_user.owner_staff_accounts.find_by(staff: @staff)
  end

  # POST /staffs
  # POST /staffs.json
  def create
    authorize! :create, Staff

    staff_outcome = Staffs::Create.run(user: super_user, attrs: params[:staff].permit!.to_h)
    staff = staff_outcome.result

    StaffAccounts::Create.run(staff: staff, owner: staff.user, params: params[:staff_account].permit!.to_h)

    params.permit![:shop_staff].each do |shop_id, attrs|
      staff.shop_staffs.where(shop_id: shop_id).update(attrs.to_h)
    end if params[:shop_staff]

    respond_to do |format|
      if staff_outcome.valid?
        format.html { redirect_to settings_user_staffs_path(super_user), notice: I18n.t("common.create_successfully_message") }
        format.json { render :show, status: :created, location: @staff }
      else
        format.html { render :new }
        format.json { render json: @staff.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /staffs/1
  # PATCH/PUT /staffs/1.json
  def update
    outcome = Staffs::Update.run(is_manager: can?(:manage, Settings),
                                 staff: @staff,
                                 attrs: params[:staff].permit!.to_h)

    staff_account_outcome = StaffAccounts::Create.run(staff: @staff, owner: @staff.user, params: params[:staff_account].permit!.to_h) if params[:staff_account]

    params.permit![:shop_staff].each do |shop_id, attrs|
      @staff.shop_staffs.where(shop_id: shop_id).update(attrs.to_h)
    end if params[:shop_staff]

    if outcome.valid? && staff_account_outcome.valid?
      if can?(:manage, Settings)
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
    Staffs::Delete.run!(staff: @staff)

    respond_to do |format|
      format.html { redirect_to settings_user_staffs_path(super_user), notice: I18n.t("common.delete_successfully_message") }
      format.json { head :no_content }
    end
  end

  private

  def set_staff
    @staff = super_user.staffs.find_by(id: params[:id])
    redirect_to settings_user_staffs_path(super_user, shop) unless @staff
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def staff_params
    params.require(:staff).permit(:first_name, :last_name, :phonetic_first_name, :phonetic_last_name, shop_ids: [])
  end
end
