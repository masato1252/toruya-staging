# frozen_string_literal: true

class Settings::ShopsController < SettingsController
  include ShopAddFeeSupport

  before_action :set_shop, only: [:show, :edit, :update, :destroy]

  # GET /shops
  # GET /shops.json
  def index
    @shops = super_user.shops.order("id").all
    @body_class = "businessSchedules"
    @shop_fee_required = shop_fee_required_for_add?(super_user)
    @proration_preview = load_shop_add_proration_preview(super_user) if @shop_fee_required
    @setup_pending_shop = super_user.shops.setup_pending.order(:id).first
  end

  # GET /shops/1
  # GET /shops/1.json
  def show
  end

  # GET /shops/new
  def new
    authorize! :create, Shop
    redirect_to settings_user_shops_path(super_user)
  end

  # GET /shops/1/edit
  def edit
    authorize! :edit, Shop
  end

  # POST /shops/add
  def add
    authorize! :create, Shop

    @outcome = Shops::AddWithFee.run(
      user: super_user,
      acting_staff: current_user.current_staff(super_user),
      authorize_token: params[:token],
      payment_intent_id: params[:payment_intent_id]
    )

    if @outcome.valid?
      shop = @outcome.result
      respond_to do |format|
        format.html { redirect_to edit_settings_user_shop_path(super_user, shop), notice: I18n.t("settings.shop.add_successfully_message") }
        format.json { render json: { redirect_path: edit_settings_user_shop_path(super_user, shop) } }
      end
    else
      error_payload = shop_add_error_payload(@outcome)

      respond_to do |format|
        format.html { redirect_to settings_user_shops_path(super_user), alert: error_payload[:message] }
        format.json { render json: error_payload, status: :unprocessable_entity }
      end
    end
  end

  # GET /shops/proration_preview
  def proration_preview
    authorize! :create, Shop

    preview = load_shop_add_proration_preview(super_user)

    render json: {
      amount: preview[:amount].fractional,
      amount_format: preview[:amount].format,
      period_start: preview[:period_start],
      period_end: preview[:period_end],
      next_renewal_date: super_user.subscription.expired_date
    }
  end

  # POST /shops
  # POST /shops.json
  def create
    authorize! :create, Shop
    redirect_to settings_user_shops_path(super_user)
  end

  # PATCH/PUT /shops/1
  # PATCH/PUT /shops/1.json
  def update
    authorize! :edit, Shop

    was_setup_pending = @shop.setup_pending?
    outcome = Shops::Update.run(shop: @shop, params: shop_params.permit!.to_h)

    if outcome.valid?
      @shop.update!(info_setup_completed: true) if was_setup_pending

      case route_to params
      when :logo
        render :edit
      when :shop
        if was_setup_pending
          redirect_to edit_settings_user_shop_business_schedules_path(super_user, @shop),
                      notice: I18n.t("settings.shop.update_successfully_message")
        else
          redirect_to settings_user_shops_path(super_user), notice: I18n.t("settings.shop.update_successfully_message")
        end
      end
    else
      flash.now[:alert] = outcome.errors.full_messages.join(", ")
      render :edit
    end
  end

  # DELETE /shops/1
  # DELETE /shops/1.json
  def destroy
    authorize! :delete, Shop

    outcome = Shops::Delete.run(shop: @shop, user: super_user)

    if outcome.valid?
      redirect_to settings_user_shops_path(super_user), notice: I18n.t("settings.shop.delete_successfully_message")
    else
      redirect_to settings_user_shops_path(super_user), alert: @shop.errors.full_messages.join(",")
    end
  end

  private

  def set_shop
    @shop = super_user.shops.find(params[:id])
  end

  def shop_params
    params.require(:shop).permit(:name, :short_name, :zip_code, :phone_number, :email, :website, :address, :logo)
  end

  def route_to params
    params[:route_to].keys.first.to_sym
  end
end
