class Settings::StaffsController < SettingsController
  before_action :set_staff, only: [:show, :edit, :update, :destroy]

  # GET /staffs
  # GET /staffs.json
  def index
    @staffs = super_user.staffs.all.order(:id)
  end

  # GET /staffs/1
  # GET /staffs/1.json
  def show
  end

  # GET /staffs/new
  def new
    @staff = super_user.staffs.new
    @shops = super_user.shops
  end

  # GET /staffs/1/edit
  def edit
    @shops = super_user.shops
  end

  # POST /staffs
  # POST /staffs.json
  def create
    @staff = super_user.staffs.new(staff_params)

    respond_to do |format|
      if @staff.save
        format.html { redirect_to settings_staffs_path, notice: I18n.t("common.create_successfully_message") }
        format.json { render :show, status: :created, location: @staff }
      else
        @shops = super_user.shops
        format.html { render :new }
        format.json { render json: @staff.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /staffs/1
  # PATCH/PUT /staffs/1.json
  def update
    outcome = Staffs::Update.run(staff: @staff, attrs: staff_params.to_h)

    respond_to do |format|
      if outcome.valid?
        format.html { redirect_to settings_staffs_path, notice: I18n.t("common.update_successfully_message") }
        format.json { render :show, status: :ok, location: @staff }
      else
        @shops = super_user.shops
        format.html { render :edit }
        format.json { render json: @staff.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /staffs/1
  # DELETE /staffs/1.json
  def destroy
    @staff.destroy
    respond_to do |format|
      format.html { redirect_to settings_staffs_path, notice: I18n.t("common.delete_successfully_message") }
      format.json { head :no_content }
    end
  end

  private

  def set_staff
    @staff = super_user.staffs.find_by(id: params[:id])
    redirect_to settings_staffs_path(shop) unless @staff
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def staff_params
    params.require(:staff).permit(:first_name, :last_name, :phonetic_first_name, :phonetic_last_name, shop_ids: [])
  end
end
