class Settings::StaffsController < DashboardController
  layout "settings"
  before_action :authenticate_user!
  before_action :set_staff, only: [:show, :edit, :update, :destroy]

  # GET /staffs
  # GET /staffs.json
  def index
    @staffs = shop.staffs.all.order(:id)
  end

  # GET /staffs/1
  # GET /staffs/1.json
  def show
  end

  # GET /staffs/new
  def new
    @staff = shop.staffs.new
    @wdays_business_schedules = []
  end

  # GET /staffs/1/edit
  def edit
    @wdays_business_schedules = shop.business_schedules.where(staff_id: @staff.id).order(:days_of_week)
  end

  # POST /staffs
  # POST /staffs.json
  def create
    @staff = shop.staffs.new(staff_params.merge(name: "#{staff_params[:last_name]} #{staff_params[:first_name]}",
                                                shortname: "#{staff_params[:last_shortname]} #{staff_params[:first_shortname]}"))

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
    business_schedules_params[:business_schedules].each do |attrs|
      CreateBusinessSchedule.run(shop: shop, staff: @staff, attrs: attrs.to_h)
    end

    respond_to do |format|
      if @staff.update(staff_params.merge(name: "#{staff_params[:last_name]} #{staff_params[:first_name]}",
                                                shortname: "#{staff_params[:last_shortname]} #{staff_params[:first_shortname]}"))
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
    params.require(:staff).permit(:first_name, :last_name, :first_shortname, :last_shortname, :full_time,
                                  menu_ids: [], staff_menus_attributes: [[:max_customers, :menu_id]])
  end

  def business_schedules_params
    params.permit(business_schedules: [:id, :business_state, :days_of_week, :start_time, :end_time])
  end
end
