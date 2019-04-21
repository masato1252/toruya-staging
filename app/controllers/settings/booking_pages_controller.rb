class Settings::BookingPagesController < SettingsController
  before_action :authorize_booking_page

  def index
    @booking_pages = super_user.booking_pages.order("id")
  end

  def new
    @booking_page = super_user.booking_pages.new
  end

  def create
    outcome = BookingPages::Create.run(user: super_user, attrs: params[:booking_page].permit!.to_h)

    debugger
    if outcome.valid?
      redirect_to settings_user_booking_pages_path(super_user), notice: I18n.t("common.create_successfully_message")
    else
      @booking_page = super_user.booking_pages.new

      render :new
    end
  end

  def edit
    @booking_page = super_user.booking_pages.find(params[:id])
  end

  def update
    @booking_page = super_user.booking_pages.find(params[:id])

    outcome = BookingPages::Update.run(booking_page: @booking_page, attrs: params[:booking_page].permit!.to_h)

    if outcome.valid?
      redirect_to settings_user_booking_pages_path(super_user), notice: I18n.t("common.create_successfully_message")
    else
      render :edit
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

  private

  def authorize_booking_page
    authorize! :manage, BookingPage
  end
end
