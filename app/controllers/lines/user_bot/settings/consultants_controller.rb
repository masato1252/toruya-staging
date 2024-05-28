# frozen_string_literal: true

class Lines::UserBot::Settings::ConsultantsController < Lines::UserBotDashboardController
  def index
    staff_ids = StaffAccount.where(user: Current.business_owner).where.not(owner: Current.business_owner).pluck(:staff_id)
    @staffs = Staff.where(id: staff_ids).undeleted.includes(:staff_account).visible.includes(:user).order(:id)
    @consultant_accounts = ConsultantAccount.pending.where(consultant_user: Current.business_owner)
  end

  def new
  end

  def create
    outcome = Consultants::Invite.run(consultant_user: Current.business_owner, phone_number: params[:phone_number])

    if outcome.valid?
      redirect_to lines_user_bot_settings_consultants_path(business_owner_id: business_owner_id), notice: I18n.t("settings.staff_account.sent_message")
    else
      render :new
    end
  end

  def new_application
  end

  def create_application
    Consultants::ApplyApplication.perform_later(
      user: Current.business_owner,
      category: params[:category],
      other_category: params[:other_category],
      support: params[:support],
      other_support: params[:other_support]
    )
    flash[:success] = I18n.t("user_bot.dashboards.settings.consultants.thanks_application")

    render json: { redirect_to: lines_user_bot_settings_consultants_path(business_owner_id: business_owner_id) }
  end
end
