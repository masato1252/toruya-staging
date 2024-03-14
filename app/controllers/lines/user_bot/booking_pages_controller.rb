# frozen_string_literal: true

class Lines::UserBot::BookingPagesController < Lines::UserBotDashboardController
  def index
    @booking_pages = Current.business_owner.booking_pages.includes(:booking_options, :shop).order("updated_at DESC")
  end

  def show
    @booking_page = Current.business_owner.booking_pages.find(params[:id])
    @booking_option = @booking_page.booking_options.first
  end

  def edit
    @booking_page = Current.business_owner.booking_pages.find(params[:id])
    @attribute = params[:attribute]

    if @attribute == "new_option"
      @options = ::BookingPages::AvailableBookingOptions.run!(shop: @booking_page.shop)
    elsif @attribute == "new_option_menu"
      @menu_result = ::Menus::CategoryGroup.run!(menu_options: menu_options)
    end
  end

  def update
    @booking_page = Current.business_owner.booking_pages.find(params[:id])

    outcome = ::BookingPages::Update.run(booking_page: @booking_page, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    render json: json_response(outcome, { redirect_to: lines_user_bot_booking_page_path(@booking_page.id, business_owner_id: business_owner_id, anchor: params[:attribute]) })
  end

  def delete_option
    @booking_page = Current.business_owner.booking_pages.find(params[:id])

    if @booking_page.booking_page_options.count > 1
      @booking_page.booking_page_options.find_by(booking_option_id: params[:booking_option_id])&.destroy

      redirect_to lines_user_bot_booking_page_path(@booking_page.id, business_owner_id: business_owner_id, anchor: "new_option")
    else
      redirect_to lines_user_bot_booking_page_path(@booking_page.id, business_owner_id: business_owner_id, anchor: "new_option"), alert: "You should have at least one booking price"
    end
  end

  def destroy
    booking_page = Current.business_owner.booking_pages.find(params[:id])

    if booking_page.update(deleted_at: Time.current)
      redirect_to lines_user_bot_booking_pages_path(business_owner_id: business_owner_id), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_booking_pages_path(business_owner_id: business_owner_id)
    end
  end

  def preview_modal
    @booking_page = Current.business_owner.booking_pages.find(params[:id])
    @booking_option = @booking_page.booking_options.first

    if @booking_option
      render layout: false
    else
      head :ok
    end
  end

  def edit_booking_options_order
    @booking_page = Current.business_owner.booking_pages.find(params[:id])
    @booking_options = @booking_page.booking_options.map { |booking_option| { label: booking_option.name, value: booking_option.id, id: booking_option.id } }
  end

  def update_booking_options_order
    booking_page = Current.business_owner.booking_pages.find(params[:id])
    outcome = BookingPages::BookingOptionsOrder.run(booking_page: booking_page, booking_option_ids: params[:booking_option_ids])

    flash[:success] = I18n.t("common.update_successfully_message")
    return_json_response(outcome, { redirect_to: lines_user_bot_booking_page_path(business_owner_id: business_owner_id) })
  end

  private

  def menu_options
    Current.business_owner.menus.map do |menu|
      if menu.shop_menus.exists?
        ::Options::MenuOption.new(id: menu.id, name: menu.display_name, minutes: menu.minutes, interval: menu.interval, online: menu.online)
      end
    end.compact
  end
end
