# frozen_string_literal: true

class Lines::UserBot::BookingOptionsController < Lines::UserBotDashboardController
  include CrossAccountRedirect
  redirect_to_correct_owner_for :booking_options, only: [:show, :edit, :update, :reorder_menu_priority, :delete_menu, :destroy]

  def new
    if compat_read_data_plane?
      render :new_compat
      return
    end

    @menu_result = ::Menus::CategoryGroup.run!(menu_options: menu_options)
    @options = ::BookingPages::AvailableBookingOptions.run!(shop: Current.business_owner.shops.first)
    @booking_pages = Current.business_owner.booking_pages.order("updated_at DESC").end_yet.filter_map { |booking_page| booking_page if !booking_page.ended? }
  end

  def create
    if compat_read_data_plane?
      owner_id = compat_booking_option_owner_id
      result = compat_v1_post(
        "/lines/user_bot/owner/#{owner_id}/booking_options",
        params.permit!.to_h
      )
      return render_compat_booking_option_result(result)
    end

    outcome = ::BookingOptions::Create.run(params.permit!.to_h.merge(user: Current.business_owner))

    if outcome.valid?
      if outcome.result&.id && outcome.result.booking_options.count == 1
        flash[:success] = I18n.t("user_bot.dashboards.booking_page_creation.create_booking_page_successfully_with_one_option")
      else
        flash[:success] = I18n.t("common.create_successfully_message")
      end
    else
      flash[:error] = I18n.t("common.something_went_wrong_message")
    end

    if outcome.valid? && outcome.result&.id
      render json: json_response(outcome, { redirect_to: lines_user_bot_booking_page_path(outcome.result.id, business_owner_id: business_owner_id) })
    else
      render json: json_response(outcome, { redirect_to: lines_user_bot_booking_options_path(business_owner_id: business_owner_id) })
    end
  end

  def index
    if compat_read_enabled?
      @booking_options = []
      return
    end

    @booking_options = Current.business_owner.booking_options.includes(:menus).order("updated_at DESC")
  end

  def show
    if compat_read_data_plane?
      render :show_compat
      return
    end

    @booking_option = Current.business_owner.booking_options.find(params[:id])
    all_menu_options = Current.business_owner.menus.map do |menu|
      ::Options::MenuOption.new(id: menu.id, name: menu.display_name, minutes: menu.minutes, interval: menu.interval, online: menu.online)
    end
    @menu_result = ::Menus::CategoryGroup.run!(menu_options: all_menu_options)
    set_up_previous_cookie("booking_page_id", params[:booking_page_id]) if params[:booking_page_id]
    clean_previous_cookie("booking_option_id")
  end

  def edit
    if compat_read_data_plane?
      render :edit_compat
      return
    end

    @booking_option = Current.business_owner.booking_options.find(params[:id])
    @attribute = params[:attribute]
    option_menu = @booking_option.booking_option_menus.find_by(menu_id: params[:menu_id])
    @booking_pages = Current.business_owner.booking_pages.normal.order("updated_at DESC")

    if option_menu
      @editing_menu = option_menu.attributes.slice("priority", "required_time", "menu_id").merge!(label: option_menu.menu.name)
    end

    @menu_result = ::Menus::CategoryGroup.run!(menu_options: menu_options)
  end

  def update
    if compat_read_data_plane?
      owner_id = compat_booking_option_owner_id
      result = compat_v1_put(
        "/lines/user_bot/owner/#{owner_id}/booking_options/#{params[:id]}",
        params.permit!.to_h
      )
      return render_compat_booking_option_result(result)
    end

    @booking_option = Current.business_owner.booking_options.find(params[:id])

    outcome = BookingOptions::Update.run(booking_option: @booking_option, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_booking_option_path(business_owner_id, @booking_option.id, anchor: params[:attribute]) })
  end

  def reorder_menu_priority
    if compat_read_data_plane?
      owner_id = compat_booking_option_owner_id
      result = compat_v1_patch(
        "/lines/user_bot/owner/#{owner_id}/booking_options/#{params[:id]}/reorder_menu_priority",
        params.permit(sorted_menus_ids: []).to_h
      )
      return head(result ? :ok : :unprocessable_entity)
    end

    @booking_option = Current.business_owner.booking_options.find(params[:id])

    outcome = BookingOptions::Update.run(booking_option: @booking_option, attrs: params.permit!.to_h, update_attribute: "menus_priority")

    head :ok
  end

  def delete_menu
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = compat_v1_delete("/lines/user_bot/owner/#{owner_id}/booking_options/#{params[:id]}/menus/#{params[:menu_id]}")

      if result&.dig("status") == "successful"
        redirect_to lines_user_bot_booking_option_path(owner_id, params[:id], anchor: "new_menu")
      else
        redirect_to lines_user_bot_booking_option_path(owner_id, params[:id], anchor: "new_menu"),
          alert: result&.dig("error_message") || I18n.t("common.operation_failed", default: "削除に失敗しました")
      end
      return
    end

    @booking_option = Current.business_owner.booking_options.find(params[:id])

    @booking_option.booking_option_menus.find_by(menu_id: params[:menu_id])&.destroy
    @booking_option.update(minutes: @booking_option.booking_option_menus.sum(:required_time))

    redirect_to lines_user_bot_booking_option_path(business_owner_id, @booking_option.id, anchor: "new_menu")
  end

  def destroy
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = compat_v1_delete("/lines/user_bot/owner/#{owner_id}/booking_options/#{params[:id]}")

      if result&.dig("status") == "successful"
        redirect_to lines_user_bot_booking_options_path(owner_id), notice: I18n.t("common.delete_successfully_message")
      else
        redirect_to lines_user_bot_booking_option_path(owner_id, params[:id]),
          flash: {
            alert: result&.dig("error_message") ||
              I18n.t("active_interaction.errors.models.booking_options/delete.attributes.booking_option.be_used_by_booking_page")
          }
      end
      return
    end

    booking_option = Current.business_owner.booking_options.find(params[:id])

    outcome = BookingOptions::Delete.run(booking_option: booking_option)

    if outcome.valid?
      redirect_to lines_user_bot_booking_options_path(business_owner_id), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_booking_option_path(business_owner_id, booking_option), flash: { alert: outcome.errors.full_messages.join(", ") }
    end
  end

  private

  def compat_booking_option_owner_id
    resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
  end

  def render_compat_booking_option_result(result)
    if result&.dig("status") == "successful"
      render json: result
    else
      render json: result || { status: "failed", error_message: "予約メニューの更新に失敗しました" },
             status: :unprocessable_entity
    end
  end

  def menu_options
    Current.business_owner.menus.map do |menu|
      if menu.shop_menus.exists?
        ::Options::MenuOption.new(id: menu.id, name: menu.display_name, minutes: menu.minutes, interval: menu.interval, online: menu.online)
      end
    end.compact
  end
end
