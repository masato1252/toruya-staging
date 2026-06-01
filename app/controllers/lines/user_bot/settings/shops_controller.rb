# frozen_string_literal: true

class Lines::UserBot::Settings::ShopsController < Lines::UserBotDashboardController
  include CrossAccountRedirect
  include ShopAddFeeSupport

  redirect_to_correct_owner_for :shops, only: [:show, :edit, :update]

  def index
    @shops = Current.business_owner.shops.order(:id)
    @shop_fee_required = shop_fee_required_for_add?(Current.business_owner)
    @proration_preview = load_shop_add_proration_preview(Current.business_owner) if @shop_fee_required
  end

  def show
    @shop = Current.business_owner.shops.find(params[:id])
    @can_delete_shop = @shop.id != Current.business_owner.shops.active.order(:id).first&.id
  end

  def edit
    @shop = Current.business_owner.shops.find(params[:id])
    @can_delete_shop = @shop.id != Current.business_owner.shops.active.order(:id).first&.id

    if params[:attribute] == "holiday_working"
      @business_schedules = @shop.business_schedules.opened.for_shop.holiday_working
      @title = I18n.t("user_bot.dashboards.settings.business_schedules.holiday_label")
      @previous_path = index_lines_user_bot_settings_business_schedules_path(business_owner_id, shop_id: params[:id])
      @header = I18n.t("user_bot.dashboards.settings.business_schedules.holiday_label")
    else
      @title = I18n.t("user_bot.dashboards.settings.shop.shop_info_label")
      @previous_path = if @shop.setup_pending?
        lines_user_bot_settings_shops_path(business_owner_id)
      else
        lines_user_bot_settings_shop_path(business_owner_id, params[:id])
      end
      @header = I18n.t("user_bot.dashboards.settings.shop.#{params[:attribute]}_label")
    end
  end

  def add
    @outcome = Shops::AddWithFee.run(
      user: Current.business_owner,
      authorize_token: params[:token],
      payment_intent_id: params[:payment_intent_id]
    )

    if @outcome.valid?
      shop = @outcome.result
      respond_to do |format|
        format.html do
          redirect_to lines_user_bot_settings_shop_path(business_owner_id, shop),
                      notice: I18n.t("settings.shop.add_successfully_message")
        end
        format.json do
          render json: { redirect_path: lines_user_bot_settings_shop_path(business_owner_id, shop) }
        end
      end
    else
      error_payload = shop_add_error_payload(@outcome)

      respond_to do |format|
        format.html do
          redirect_to lines_user_bot_settings_shops_path(business_owner_id), alert: error_payload[:message]
        end
        format.json { render json: error_payload, status: :unprocessable_entity }
      end
    end
  end

  def proration_preview
    preview = load_shop_add_proration_preview(Current.business_owner)

    render json: {
      amount: preview[:amount].fractional,
      amount_format: preview[:amount].format,
      period_start: preview[:period_start],
      period_end: preview[:period_end],
      next_renewal_date: Current.business_owner.subscription.expired_date
    }
  end

  def update
    shop = Current.business_owner.shops.find(params[:id])
    was_setup_pending = shop.setup_pending?
    outcome = Shops::Update.run(shop: shop, params: shop_params.to_h)

    if outcome.valid? && was_setup_pending && shop_setup_completion_attribute?
      shop.update!(info_setup_completed: true)
    end

    case params[:attribute]
    when "holiday_working"
      return_json_response(outcome, { redirect_to: index_lines_user_bot_settings_business_schedules_path(business_owner_id, shop_id: params[:id]) })
    else
      redirect_path = if was_setup_pending && shop_setup_completion_attribute?
        index_lines_user_bot_settings_business_schedules_path(business_owner_id, shop_id: shop.id)
      else
        lines_user_bot_settings_shop_path(business_owner_id, shop_id: shop.id)
      end
      return_json_response(outcome, { redirect_to: redirect_path })
    end
  end

  def custom_messages
  end

  def destroy
    shop = Current.business_owner.shops.find(params[:id])
    default_shop = Current.business_owner.shops.active.order(:id).first

    if shop.id == default_shop&.id
      respond_to do |format|
        format.json { render json: { error_message: I18n.t("settings.shop.cannot_delete_default_message") }, status: :unprocessable_entity }
        format.html { redirect_to lines_user_bot_settings_shops_path(business_owner_id), alert: I18n.t("settings.shop.cannot_delete_default_message") }
      end
      return
    end

    outcome = Shops::Delete.run(shop: shop, user: Current.business_owner)
    if outcome.valid?
      respond_to do |format|
        format.json do
          render json: {
            redirect_to: lines_user_bot_settings_shops_path(business_owner_id),
            notice: I18n.t("settings.shop.delete_successfully_message")
          }
        end
        format.html do
          redirect_to lines_user_bot_settings_shops_path(business_owner_id),
                      notice: I18n.t("settings.shop.delete_successfully_message")
        end
      end
    else
      respond_to do |format|
        format.json { render json: { error_message: shop.errors.full_messages.join(",") }, status: :unprocessable_entity }
        format.html { redirect_to lines_user_bot_settings_shop_path(business_owner_id, shop), alert: shop.errors.full_messages.join(",") }
      end
    end
  end

  private

  def shop_setup_completion_attribute?
    %w[name address phone_number logo website].include?(params[:attribute])
  end

  def shop_params
    params.permit(:holiday_working, :name, :short_name, :phone_number, :website, :email, :logo, :holiday_working_option, business_schedules: [:start_time, :end_time], address_details: [:zip_code, :region, :city, :street1, :street2])
  end
end
