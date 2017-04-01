class ReservationsController < DashboardController
  before_action :set_reservation, only: [:show, :edit, :update, :destroy]

  # GET /reservations
  # GET /reservations.json
  def index
    @body_class = "shopIndex"
    date = params[:reservation_date] ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date
    holidays = Holidays.between(date.beginning_of_month, date.end_of_month)
    @holiday_days = holidays.map { |holiday| holiday[:date].day }
    @reservations = shop.reservations.visible.in_date(date).
      includes(:menu, :customers, :staffs).
      order("reservations.start_time ASC")
    @staffs_working_schedules = Shops::StaffsWorkingSchedules.run!(shop: shop, date: date)
    @working_time_range = Reservable::Time.run!(shop: shop, date: date)
  end

  # GET /reservations/new
  def new
    @body_class = "resNew"

    @reservation = shop.reservations.new(start_time_date_part: params[:start_time_date_part] || Time.zone.now.to_s(:date),
                                         start_time_time_part: params[:start_time_time_part] || Time.zone.now.to_s(:time),
                                         end_time_time_part: params[:end_time_time_part],
                                         memo: params[:memo],
                                         menu_id: params[:menu_id],
                                         staff_ids: params[:staff_ids].try(:split, ",").try(:uniq),
                                         customer_ids: params[:customer_ids].try(:split, ",").try(:uniq))
    if params[:menu_id].present?
      @result = Reservations::RetrieveAvailableMenus.run!(shop: shop, params: params.permit!.to_h)
    end

    if params[:start_time_date_part].present?
      @time_ranges = Reservable::Time.run!(shop: shop, date: Time.zone.parse(params[:start_time_date_part]).to_date)
    end
  end

  # GET /reservations/1/edit
  def edit
    @body_class = "resNew"
    @result = Reservations::RetrieveAvailableMenus.run!(shop: shop, reservation: @reservation, params: params.permit!.to_h)
    @time_ranges = Reservable::Time.run!(shop: shop, date: @reservation.start_time.to_date)
  end

  # POST /reservations
  # POST /reservations.json
  def create
    outcome = Reservations::AddReservation.run(shop: shop, user: current_user, params: reservation_params.to_h)

    respond_to do |format|
      if outcome.valid?
        format.html { redirect_to shop_reservations_path(shop, reservation_date: reservation_params[:start_time_date_part]), notice: I18n.t("reservation.create_successfully_message") }
      else
        format.html { redirect_to new_shop_reservation_path(shop, reservation_params.to_h), alert: outcome.errors.full_messages.join(", ") }
      end
    end
  end

  # PATCH/PUT /reservations/1
  # PATCH/PUT /reservations/1.json
  def update
    outcome = Reservations::AddReservation.run(shop: shop, user: current_user, reservation: @reservation, params: reservation_params.to_h)

    respond_to do |format|
      if outcome.valid?
        format.html do
          if params[:from_customer_id]
            redirect_to shop_customers_path(shop_id: params[:shop_id], customer_id: params[:from_customer_id])
          else
            redirect_to shop_reservations_path(shop, reservation_date: reservation_params[:start_time_date_part]), notice: I18n.t("reservation.update_successfully_message")
          end
        end
        format.json { render :show, status: :ok, location: @reservation }
      else
        @result = Reservations::RetrieveAvailableMenus.run!(shop: shop, reservation: @reservation, params: reservation_params.to_h)
        format.html { render :edit }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reservations/1
  # DELETE /reservations/1.json
  def destroy
    @reservation.destroy
    respond_to do |format|
      format.html { redirect_to shop_reservations_path(shop), notice: I18n.t("reservation.delete_successfully_message") }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_reservation
    @reservation = shop.reservations.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def reservation_params
    params.require(:reservation).permit(:menu_id, :start_time_date_part, :start_time_time_part, :end_time_time_part,
                                        :customer_ids, :staff_ids, :memo)
  end
end
