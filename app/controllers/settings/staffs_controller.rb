class Settings::StaffsController < DashboardController
  layout "settings"
  before_action :authenticate_user!
  before_action :set_staff, only: [:show, :edit, :update, :destroy]

  # GET /staffs
  # GET /staffs.json
  def index
    @staffs = shop.staffs.all
  end

  # GET /staffs/1
  # GET /staffs/1.json
  def show
  end

  # GET /staffs/new
  def new
    @staff = shop.staffs.new
  end

  # GET /staffs/1/edit
  def edit
  end

  # POST /staffs
  # POST /staffs.json
  def create
    @staff = shop.staffs.new(staff_params)

    respond_to do |format|
      if @staff.save
        format.html { redirect_to settings_shop_staffs_path(shop), notice: 'Staff was successfully created.' }
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
    respond_to do |format|
      if @staff.update(staff_params)
        format.html { redirect_to settings_shop_staffs_path(shop), notice: 'Staff was successfully updated.' }
        format.json { render :show, status: :ok, location: @staff }
      else
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
      format.html { redirect_to settings_shop_staffs_path(shop), notice: 'Staff was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  def set_staff
    @staff = shop.staffs.find_by(id: params[:id])
    redirect_to settings_shop_staffs_path(shop) unless @staff
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def staff_params
    params.require(:staff).permit(:name, :shortname,
                                  menu_ids: [], staff_menus_attributes: [[:max_customers, :menu_id]])
  end
end
