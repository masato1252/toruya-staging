# frozen_string_literal: true

require "utils"

class Lines::UserBot::Settings::SocialRichMenusController < Lines::UserBotDashboardController
  def index
    @current_rich_menu = Current.business_owner.social_account.current_rich_menu
    @pending_rich_menus = Current.business_owner.social_account.social_rich_menus.pending
  end

  def new
    @rich_menu = Current.business_owner.social_account.social_rich_menus.new
    @sale_pages = Current.business_owner.sale_pages.includes(:product).order("updated_at DESC")
    @booking_pages = Current.business_owner.booking_pages.started.order("updated_at DESC")

    render :edit
  end

  def edit
    @rich_menu = Current.business_owner.social_account.social_rich_menus.find(params[:id])
    @sale_pages = Current.business_owner.sale_pages.includes(:product).order("updated_at DESC")
    @booking_pages = Current.business_owner.booking_pages.started.order("updated_at DESC")
  end

  def upsert
    if params[:image].blank? &&
        params[:social_name].present? &&
        (menu = Current.business_owner.social_account.social_rich_menus.find_by(social_name: params[:social_name])) && menu.image.attached?
      tempfile = Utils.file_from_url(menu.image.url)
      params[:image] = tempfile
    end

    outcome = RichMenus::Upsert.run(
      social_account: Current.business_owner.social_account,
      social_name: params[:social_name],
      internal_name: params[:internal_name],
      bar_label: params[:bar_label],
      image: params[:image],
      layout_type: params[:layout_type],
      actions: params.permit![:actions],
      current: params[:current],
      default: params[:default]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_settings_social_account_social_rich_menus_path(business_owner_id: business_owner_id) })
  end

  def destroy
  end

  def current
    rich_menu = Current.business_owner.social_account.social_rich_menus.find(params[:id])
    RichMenus::SetCurrent.run(social_rich_menu: rich_menu)
    HiEventJob.perform_later(rich_menu.social_account, "rich_menu_switch")

    redirect_to lines_user_bot_settings_social_account_social_rich_menus_path(business_owner_id: business_owner_id)
  end
end
