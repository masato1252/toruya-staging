# frozen_string_literal: true

class Lines::UserBot::Settings::StaffsController < Lines::UserBotDashboardController
  before_action :set_staff, only: [:show, :edit, :update, :destroy, :resend_activation_sms]

  def index
    @staffs = Staff.where(user: Current.business_owner).undeleted.includes(:staff_account).order(:id)
  end

  def new
    authorize! :create, Staff
  end

  def edit
  end

  def create
    authorize! :create, Staff

    outcome = Staffs::Invite.run(user: Current.business_owner, phone_number: params[:phone_number])

    if outcome.valid?
      redirect_to lines_user_bot_settings_staffs_path, notice: I18n.t("settings.staff_account.sent_message")
    else
      render :new
    end
  end

  def update
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

  def resend_activation_email
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
