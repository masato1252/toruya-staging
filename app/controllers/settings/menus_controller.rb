class Settings::MenusController < DashboardController
  layout "settings"
  before_action :authenticate_user!
  before_action :set_menu, only: [:show, :edit, :update, :destroy]

  # GET /settings/menus
  # GET /settings/menus.json
  def index
    @menus = super_user.menus.includes(:staffs).all
  end

  # GET /settings/menus/1
  # GET /settings/menus/1.json
  def show
  end

  # GET /settings/menus/new
  def new
    @menu = super_user.menus.new
  end

  # GET /settings/menus/1/edit
  def edit
  end

  # POST /settings/menus
  # POST /settings/menus.json
  def create
    @menu = super_user.menus.new(menu_params)

    respond_to do |format|
      if @menu.save
        format.html { redirect_to settings_menus_path, notice: 'Menu was successfully created.' }
        format.json { render :show, status: :created, location: @menu }
      else
        format.html { render :new }
        format.json { render json: @settings_menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /settings/menus/1
  # PATCH/PUT /settings/menus/1.json
  def update
    respond_to do |format|
      # TODO: we always return staff_ids=[] to delete all its staff_menus, then create again. Try to fix it in right way.
      if @menu.update(menu_params)
        format.html { redirect_to settings_menus_path, notice: 'Menu was successfully updated.' }
        format.json { render :show, status: :ok, location: @menu }
      else
        format.html { render :edit }
        format.json { render json: @settings_menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /settings/menus/1
  # DELETE /settings/menus/1.json
  def destroy
    @menu.destroy
    respond_to do |format|
      format.html { redirect_to settings_shop_menus_path(shop), notice: 'Menu was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_menu
    @menu = super_user.menus.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def menu_params
    @menu_params ||= params.require(:menu).permit(
    :name, :shortname, :minutes, :interval, :min_staffs_number, :max_seat_number,
    staff_ids: [], shop_ids: [],
    staff_menus_attributes: [[:id, :max_customers, :staff_id, :_destroy]])
  end
end
