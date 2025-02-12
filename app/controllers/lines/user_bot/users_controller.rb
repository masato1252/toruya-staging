# frozen_string_literal: true

class Lines::UserBot::UsersController < Lines::UserBotController
  protect_from_forgery with: :exception, prepend: true
  skip_before_action :authenticate_social_user!, only: [:line_sign_up]

  # social user sign up
  def line_sign_up
    render layout: 'booking'
  end

  # user login
  def connect
    render layout: 'booking'
  end

  # user sign up
  def sign_up
    @staff_account = StaffAccount.find_by(token: params[:staff_token]) if params[:staff_token].present?
    render layout: 'booking'
  end

  def generate_code
    if I18n.locale == :ja && (Phonelib.invalid_for_country?(params[:phone_number], 'JP') && Phonelib.invalid?(params[:phone_number]))
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
    user = Users::CreateFromPhone.run!(
      last_name: params[:last_name],
      first_name: params[:first_name],
      phonetic_last_name: params[:phonetic_last_name],
      phonetic_first_name: params[:phonetic_first_name],
      phone_number: params[:phone_number],
      email: params[:email],
      referral_token: params[:referral_token],
      where_know_toruya: params[:where_know_toruya],
      what_main_problem: params[:what_main_problem],
      social_user: social_user,
      invited_as_staff: params[:staff_token].present?
    )

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
    user = Profiles::UpdateShopInfo.run!(
      user: current_user,
      social_user: social_user,
      params: {
        company_name: params[:company_name],
        company_phone_number: params[:company_phone_number],
        zip_code: params[:zip_code],
        region: params[:region],
        city: params[:city],
        street1: params[:street1],
        street2: params[:street2]
      }
    )

    head :ok
  end

  def check_shop_profile
    if current_user && params[:staff_token]
      outcome = StaffAccounts::ConnectUser.run(token: params[:staff_token], user: current_user)

      if outcome.valid?
        render json: { is_shop_profile_created: current_user&.profile&.company_address_details&.present? }
      else
        write_user_bot_cookies(:current_user_id, nil)

        head :bad_request
      end
    else
      render json: { is_shop_profile_created: current_user&.profile&.company_address_details&.present? }
    end
  end
end
