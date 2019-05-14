class Settings::BookingPagesController < SettingsController
  before_action :authorize_booking_page

  def index
    @booking_pages = super_user.booking_pages.order("id")
  end

  def new
    @booking_page = super_user.booking_pages.new
    render :form
  end

  def create
    outcome = BookingPages::Save.run(booking_page: super_user.booking_pages.new, attrs: params[:booking_page].permit!.to_h)

    if outcome.valid?
      redirect_to settings_user_booking_pages_path(super_user), notice: I18n.t("common.create_successfully_message")
    else
      @booking_page = super_user.booking_pages.new

      render :form
    end
  end

  def edit
    @booking_page = super_user.booking_pages.find(params[:id])
    render :form
  end

  def update
    @booking_page = super_user.booking_pages.find(params[:id])

    outcome = BookingPages::Save.run(booking_page: @booking_page, attrs: params[:booking_page].permit!.to_h)

    if outcome.valid?
      redirect_to settings_user_booking_pages_path(super_user), notice: I18n.t("common.create_successfully_message")
    else
      render :form
    end
  end

  def destroy
    booking_page = super_user.booking_pages.find(params[:id])

    if booking_page.destroy
      redirect_to settings_user_booking_pages_path(super_user), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to settings_user_booking_pages_path(super_user)
    end
  end

  def copy_modal
    @booking_page = super_user.booking_pages.find(params[:id])

    render layout: false
  end

  def validate_special_dates
    outcome = Booking::ValidateSpecialDates.run(shop: super_user.shops.find(params[:shop_id]), special_dates: params[:special_dates])

    render json: { message: outcome.errors.full_messages.join(", ") }
  end

  private

  def authorize_booking_page
    authorize! :manage, BookingPage
  end
end
