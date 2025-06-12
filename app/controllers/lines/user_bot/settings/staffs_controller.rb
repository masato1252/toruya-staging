# frozen_string_literal: true

class Lines::UserBot::Settings::StaffsController < Lines::UserBotDashboardController
  before_action :set_staff, only: [:show, :edit, :update, :destroy, :resend_activation_sms]

  def index
    @staffs = Staff.where(user: Current.business_owner).undeleted.includes(:staff_account).visible.order(:id)
  end

  def new
  end

  def show
  end

  def edit
    case params[:attribute]
    when "staff_menus"
      staff_menus = @staff.staff_menus.includes(:menu).to_a
      @staff_menus_options = Current.business_owner.menus.active.order(:name).map do |menu|
        if staff_menu = staff_menus.find { |staff_menu| staff_menu.menu_id == menu.id }
          Option.new(
            name: menu.name,
            menu_id: menu.id,
            max_customers: staff_menu.max_customers,
            checked: true
          )
        else
          Option.new(
            name: menu.name,
            menu_id: menu.id,
            max_customers: 1,
            checked: false
          )
        end
      end
    end
  end

  def create
    outcome = Staffs::Invite.run(user: Current.business_owner, phone_number: params[:phone_number])

    if outcome.valid?
      redirect_to edit_lines_user_bot_settings_staff_path(business_owner_id: Current.business_owner.id, id: outcome.result.id, attribute: :staff_menus), notice: I18n.t("common.create_successfully_message")
    else
      render :new
    end
  end

  def update
    outcome = Staffs::Patch.run(
      staff: @staff,
      attribute: params[:attribute],
      last_name: params[:last_name],
      first_name: params[:first_name],
      phonetic_last_name: params[:phonetic_last_name],
      phonetic_first_name: params[:phonetic_first_name],
      phone_number: params[:phone_number],
      picture: params[:picture],
      introduction: params[:introduction],
      staff_menus: params[:staff_menus]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_settings_staff_path(Current.business_owner, @staff) })
  end

  def destroy
    authorize! :delete, Staff
    outcome = Staffs::Delete.run(staff: @staff)

    if outcome.valid?
      redirect_to lines_user_bot_settings_staffs_path(Current.business_owner), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_settings_staffs_path(Current.business_owner), alert: outcome.errors.full_messages.join(", ")
    end
  end

  def resend_activation_sms
    Notifiers::Users::Notifications::ActivateStaffAccount.run(receiver: @staff.staff_account, user: @staff.staff_account.owner)

    flash[:success] = I18n.t("settings.staff_account.sent_message")
    redirect_back(fallback_location: lines_user_bot_settings_staff_path(Current.business_owner, @staff))
  end

  private

  def set_staff
    @staff = Staff.find_by(id: params[:id], user_id: Current.business_owner.id)
    redirect_to settings_user_staffs_path(Current.business_owner, shop) unless @staff
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def staff_params
    params.require(:staff).permit(:first_name, :last_name, :phonetic_first_name, :phonetic_last_name, shop_ids: [])
  end
end
