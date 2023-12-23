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
  end

  def create
    outcome = Staffs::Invite.run(user: Current.business_owner, phone_number: params[:phone_number])

    if outcome.valid?
      redirect_to lines_user_bot_settings_staffs_path(business_owner_id: business_owner_id), notice: I18n.t("settings.staff_account.sent_message")
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
      introduction: params[:introduction]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_settings_staff_path(Current.business_owner, @staff) })
  end

  def destroy
    authorize! :delete, Staff
    outcome = Staffs::Delete.run(staff: @staff)

    if outcome.valid?
      redirect_to lines_user_bot_settings_staffs_path(Current.business_owner), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_settings_staffs_path(Current.business_owner)
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
