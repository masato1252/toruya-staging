class Settings::MenusController < SettingsController
  before_action :set_menu, only: [:show, :edit, :update, :destroy]

  # GET /settings/menus
  # GET /settings/menus.json
  def index
    # XXX: FOR FUN
    # @menus = super_user.menus.left_outer_joins(:active_staffs, :reservation_setting).select("DISTINCT menus.*, MIN(COALESCE(NULLIF(reservation_settings.short_name, ''), reservation_settings.name)) as setting_name, COUNT(DISTINCT(staff_menus.staff_id)) as staffs_count").group("menus.id").order("id")
    @menus = super_user.menus.includes(:active_staffs, :reservation_setting).order("id")
  end

  # GET /settings/menus/1
  # GET /settings/menus/1.json
  def show
  end

  # GET /settings/menus/new
  def new
    @menu = super_user.menus.new
    @menu_reservation_setting_rule = @menu.menu_reservation_setting_rule || @menu.build_menu_reservation_setting_rule(start_date: Time.zone.now.to_date)
    @reservation_setting = @menu.reservation_setting || super_user.reservation_settings.find_by(id: params[:reservation_setting_id]) || super_user.reservation_settings.first
    @shops = if can?(:manage, :all)
               super_user.shops.order("id")
             else
               [shop]
             end
  end

  # GET /settings/menus/1/edit
  def edit
    @menu_reservation_setting_rule = @menu.menu_reservation_setting_rule || @menu.build_menu_reservation_setting_rule(start_date: Time.zone.now.to_date)
    @reservation_setting = @menu.reservation_setting || super_user.reservation_settings.find_by(id: params[:reservation_setting_id]) || super_user.reservation_settings.first

    @shops = if can?(:manage, :all)
               super_user.shops.order("id")
             else
               [shop]
             end
  end

  # POST /settings/menus
  # POST /settings/menus.json
  def create
    @menu = super_user.menus.new

    respond_to do |format|
      outcome = Menus::Update.run(menu: @menu,
                                  attrs: menu_params.to_h.except(:reservation_setting_id,
                                                                 :menu_reservation_setting_rule_attributes,
                                                                 :new_categories),
                                  new_categories: menu_params[:new_categories],
                                  reservation_setting_id: menu_params[:reservation_setting_id],
                                  menu_reservation_setting_rule_attributes: menu_params[:menu_reservation_setting_rule_attributes].to_h)

      if outcome.valid?
        format.html { redirect_to settings_user_menus_path(super_user), notice: I18n.t("common.create_successfully_message") }
        format.json { render :show, status: :ok, location: @menu }
      else
        format.html { render :edit }
        format.json { render json: @settings_menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /settings/menus/1
  # PATCH/PUT /settings/menus/1.json
  def update
    respond_to do |format|
      outcome = Menus::Update.run(menu: @menu,
                                  attrs: menu_params.to_h.except(:reservation_setting_id,
                                                                 :menu_reservation_setting_rule_attributes,
                                                                 :new_categories),
                                  new_categories: menu_params[:new_categories],
                                  reservation_setting_id: menu_params[:reservation_setting_id],
                                  menu_reservation_setting_rule_attributes: menu_params[:menu_reservation_setting_rule_attributes].to_h)

      if outcome.valid?
        format.html { redirect_to settings_user_menus_path(super_user), notice: I18n.t("common.update_successfully_message") }
        format.json { render :show, status: :ok, location: @menu }
      else
        format.html { render :edit }
        format.json { render json: @settings_menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /settings/menus/1
  # DELETE /settings/menus/1.json
  def destroy
    @menu.destroy
    respond_to do |format|
      format.html { redirect_to settings_user_menus_path(super_user), notice: I18n.t("common.delete_successfully_message") }
      format.json { head :no_content }
    end
  end

  def repeating_dates
    shop_repeating_dates =  Menus::RetrieveRepeatingDates.run!(reservation_setting_id: params[:reservation_setting_id],
                                                               shop_ids: params[:shop_ids].try(:split, ","),
                                                               repeats: params[:repeats],
                                                               start_date: params[:start_date])
    sentence = shop_repeating_dates.map do |shop_repeating_date|
      name = shop_repeating_date[:shop] ? shop_repeating_date[:shop].name : ""
      dates = shop_repeating_date[:dates]
      if name.present?
        # "#{name}: #{shop_repeating_date[:dates].join(", ")}"
        "#{name}: #{shop_repeating_date[:dates].last}"
      else
        shop_repeating_date[:dates].last
      end
    end.join("; ")

    render json: {sentence: sentence}
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_menu
    @menu = super_user.menus.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def menu_params
    @menu_params ||= params.require(:menu).permit(
    :name, :short_name, :minutes, :interval, :min_staffs_number, :max_seat_number,
    :reservation_setting_id,
    staff_ids: [], category_ids: [],
    new_categories: [],
    staff_menus_attributes: [[:id, :max_customers, :staff_id, :_destroy]],
    shop_menus_attributes: [[:id, :max_seat_number, :shop_id, :_destroy]],
    menu_reservation_setting_rule_attributes: [:start_date, :end_date, :repeats, :reservation_type],
    )
  end
end
