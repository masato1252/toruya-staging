class Settings::ShopsController < SettingsController
  before_action :set_shop, only: [:show, :edit, :update, :destroy]

  # GET /shops
  # GET /shops.json
  def index
    @shops = super_user.shops.order("id").all
    @body_class = "businessSchedules"
  end

  # GET /shops/1
  # GET /shops/1.json
  def show
  end

  # GET /shops/new
  def new
    authorize! :create, Shop
    @shop = super_user.shops.new
  end

  # GET /shops/1/edit
  def edit
  end

  # POST /shops
  # POST /shops.json
  def create
    authorize! :create, Shop
    outcome = Shops::Create.run(user: super_user, params: shop_params.permit!.to_h, authorize_token: params[:token])

    if outcome.valid?
      redirect_to settings_user_shops_path(super_user) , notice: I18n.t("settings.shop.create_successfully_message")
    else
      @shop = super_user.shops.new(shop_params)
      @shop.valid?

      render :new
    end
  end

  # PATCH/PUT /shops/1
  # PATCH/PUT /shops/1.json
  def update
    if @shop.update(shop_params)
      redirect_to settings_user_shops_path(super_user), notice: I18n.t("settings.shop.update_successfully_message")
    else
      render :edit
    end
  end

  # DELETE /shops/1
  # DELETE /shops/1.json
  def destroy
    @shop.destroy
    redirect_to settings_user_shops_path(super_user), notice: I18n.t("settings.shop.delete_successfully_message")
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_shop
    @shop = super_user.shops.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def shop_params
    params.require(:shop).permit(:name, :short_name, :zip_code, :phone_number, :email, :website, :address)
  end
end
