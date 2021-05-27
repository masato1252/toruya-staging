# frozen_string_literal: true

class Lines::UserBot::BookingPagesController < Lines::UserBotDashboardController
  before_action :authorize_booking_page

  def index
    @booking_pages = super_user.booking_pages.includes(:booking_options, :shop).order("updated_at DESC")
  end

  def show
    @booking_page = super_user.booking_pages.find(params[:id])
  end

  def edit
    @booking_page = super_user.booking_pages.find(params[:id])
    @attribute = params[:attribute]

    if @attribute == "new_option"
      @options = ::BookingPages::AvailableBookingOptions.run!(shop: @booking_page.shop)
    end
  end

  def update
    @booking_page = super_user.booking_pages.find(params[:id])

    outcome = ::BookingPages::Update.run(booking_page: @booking_page, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    render json: json_response(outcome, { redirect_to: lines_user_bot_booking_page_path(@booking_page.id, anchor: params[:attribute]) })
  end

  def delete_option
    @booking_page = super_user.booking_pages.find(params[:id])
    @booking_page.booking_page_options.find_by(booking_option_id: params[:booking_option_id]).destroy

    redirect_to lines_user_bot_booking_page_path(@booking_page.id, anchor: "new_option")
  end

  def destroy
    booking_page = super_user.booking_pages.find(params[:id])

    if booking_page.update(deleted_at: Time.current)
      redirect_to lines_user_bot_booking_pages_path, notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_booking_pages_path
    end
  end

  def preview_modal
    @booking_page = super_user.booking_pages.find(params[:id])
    @booking_option = @booking_page.booking_options.first

    if @booking_option
      render layout: false
    else
      head :ok
    end
  end

  private

  def authorize_booking_page
    authorize! :manage, BookingPage
  end
end
