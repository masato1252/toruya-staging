# frozen_string_literal: true

class Lines::UserBot::UsersController < Lines::UserBotController
  protect_from_forgery with: :exception, prepend: true
  skip_before_action :authenticate_social_user!, only: [:line_sign_up]

  # social user sign up
  def line_sign_up
    @staff_account = StaffAccount.find_by(token: params[:staff_token]) if params[:staff_token].present?
    render layout: 'booking'
  end

  # user login
  def connect
    @staff_account = StaffAccount.find_by(token: params[:staff_token]) if params[:staff_token].present?
    render layout: 'booking'
  end

  # user sign up
  def sign_up
    @staff_account = StaffAccount.find_by(token: params[:staff_token]) if params[:staff_token].present?
    render layout: 'booking'
  end

  def generate_code
    phone = Phonelib.parse(params[:phone_number])
    unless phone.valid?
      Rollbar.error("User sign up invalid phone number", phone_number: params[:phone_number])
      render json: {
        user_id: nil,
        errors: {
          message: I18n.t("errors.invalid_jp_phone_number")
        }
      }
      return
    end

    identification_code = IdentificationCodes::Create.run!(
      phone_number: params[:phone_number]
    )

    render json: {
      uuid: identification_code.uuid,
      user_id: User.find_by(phone_number: Phonelib.parse(params[:phone_number]).international(false))&.id,
      errors: {
        message: params[:login_type] == 'sign_in' ? I18n.t("user_bot.guest.user_connect.message.unmatch_phone_number") : nil
      }
    }
  end

  def create_user
    outcome = Users::CreateFromPhone.run(
      last_name: params[:last_name],
      first_name: params[:first_name],
      phonetic_last_name: params[:phonetic_last_name],
      phonetic_first_name: params[:phonetic_first_name],
      phone_number: params[:phone_number],
      email: params[:email],
      zip_code: params[:zip_code],
      region: params[:region],
      city: params[:city],
      street1: params[:street1],
      street2: params[:street2],
      referral_token: params[:referral_token],
      where_know_toruya: params[:where_know_toruya],
      what_main_problem: params[:what_main_problem],
      social_user: social_user,
      invited_as_staff: params[:staff_token].present?
    )

    unless outcome.valid?
      render json: { errors: outcome.errors.messages }, status: :unprocessable_entity
      return
    end

    user = outcome.result

    ApplicationRecord.transaction do
      booking_code = BookingCode.find_by!(uuid: params[:uuid])
      booking_code.update!(user_id: user.id)

      if params[:staff_token]
        staff_account = StaffAccounts::ConnectUser.run!(token: params[:staff_token], user: user)
        Notifiers::Users::Notifications::UserSignedUpAsStaff.run(receiver: staff_account.user, owner: staff_account.owner)
      end
    end

    write_user_bot_cookies(:current_user_id, user.id)

    render json: { user_id: user.id }
  end

  # It is login in behavior, either
  def identify_code
    outcome = IdentificationCodes::VerifyUser.run(
      social_user: social_user,
      phone_number: params[:phone_number],
      uuid: params[:uuid],
      code: params[:code],
      staff_token: params[:staff_token],
      consultant_token: params[:consultant_token]
    )

    if outcome.valid?
      identification_code = outcome.result
      if social_user.user
        write_user_bot_cookies(:current_user_id, social_user.user_id)
      end

      render json: { identification_successful: true, user_id: social_user.user_id }
    else
      render json: {
        identification_successful: false,
        errors: {
          message: outcome.errors.full_messages.to_sentence
        }
      }
    end
  end

  def create_shop_profile
    if (pending_sa = find_pending_staff_account(current_user))
      activate_pending_staff_account(pending_sa, current_user)
      head :ok
      return
    end

    outcome = Profiles::UpdateShopInfo.run(
      user: current_user,
      social_user: social_user,
      params: {
        company_name: params[:company_name],
        company_phone_number: params[:company_phone_number],
        company_email: params[:company_email],
        zip_code: params[:zip_code],
        region: params[:region],
        city: params[:city],
        street1: params[:street1],
        street2: params[:street2]
      }
    )

    if outcome.valid?
      render json: { redirect_url: lines_user_bot_settings_path(business_owner_id: current_user.id) }
    else
      render json: { errors: outcome.errors.messages }, status: :unprocessable_entity
    end
  end

  def check_shop_profile
    if current_user && params[:staff_token]
      outcome = StaffAccounts::ConnectUser.run(token: params[:staff_token], user: current_user)

      if outcome.valid?
        staff_account = outcome.result
        render json: {
          is_shop_profile_created: true,
          redirect_url: lines_user_bot_settings_path(business_owner_id: staff_account.owner_id)
        }
      else
        write_user_bot_cookies(:current_user_id, nil)

        head :bad_request
      end
    elsif current_user && current_user.staff_accounts.active.where.not(owner_id: current_user.id).exists?
      staff_account = current_user.staff_accounts.active.where.not(owner_id: current_user.id).first

      begin
        if social_user && Rails.env.production?
          dashboard_menu = SocialRichMenu.find_by(social_name: UserBotLines::RichMenus::Dashboard::KEY, locale: social_user.locale)
          if dashboard_menu && social_user.social_rich_menu_key != dashboard_menu.social_name
            RichMenus::Connect.run(social_target: social_user, social_rich_menu: dashboard_menu)
            Rails.logger.info "[check_shop_profile] Switched rich menu to Dashboard for social_user##{social_user.id}"
          end
        end
      rescue => e
        Rails.logger.error "[check_shop_profile] Rich menu switch failed: #{e.class} #{e.message}"
      end

      render json: {
        is_shop_profile_created: true,
        redirect_url: lines_user_bot_settings_path(business_owner_id: staff_account.owner_id)
      }
    elsif current_user && (pending_sa = find_pending_staff_account(current_user))
      activate_pending_staff_account(pending_sa, current_user)

      render json: {
        is_shop_profile_created: true,
        redirect_url: lines_user_bot_settings_path(business_owner_id: pending_sa.owner_id)
      }
    else
      render json: { is_shop_profile_created: current_user&.profile&.company_address_details&.present? }
    end
  end

  private

  def find_pending_staff_account(user)
    return nil unless user&.phone_number.present?

    StaffAccount.pending
      .where(phone_number: user.phone_number)
      .where.not(owner_id: user.id)
      .first
  end

  def activate_pending_staff_account(staff_account, user)
    staff_account.user = user
    staff_account.mark_active

    return unless staff_account.save

    staff = staff_account.staff
    staff.update(
      last_name: staff.last_name.presence || user.profile&.last_name,
      first_name: staff.first_name.presence || user.profile&.first_name,
      phonetic_last_name: staff.phonetic_last_name.presence || user.profile&.phonetic_last_name,
      phonetic_first_name: staff.phonetic_first_name.presence || user.profile&.phonetic_first_name
    )

    begin
      social = user.social_user
      if social && Rails.env.production?
        dashboard_menu = SocialRichMenu.find_by(social_name: UserBotLines::RichMenus::Dashboard::KEY, locale: social.locale)
        if dashboard_menu
          RichMenus::Connect.run(social_target: social, social_rich_menu: dashboard_menu)
        end
      end
    rescue => e
      Rails.logger.error "[activate_pending_staff_account] Rich menu switch failed for user##{user.id}: #{e.class} #{e.message}"
    end

    Notifiers::Users::Notifications::StaffJoined.perform_later(receiver: staff_account.owner, staff_name: staff.name)
  end
end
