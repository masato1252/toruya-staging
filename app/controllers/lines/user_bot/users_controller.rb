class Lines::UserBot::UsersController < Lines::UserBotController
  protect_from_forgery with: :exception, prepend: true

  def connect; end

  def sign_up; end

  def generate_code
    identification_code = IdentificationCodes::CreateForUser.run!(
      phone_number: params[:phone_number]
    )

    render json: {
      uuid: identification_code.uuid,
      user_id: User.find_by(phone_number: params[:phone_number])&.id
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
      social_user: social_user
    )

    ApplicationRecord.transaction do
      booking_code = BookingCode.find_by!(uuid: params[:uuid])
      booking_code.update!(user_id: user.id)
    end

    render json: { user_id: user.id }
  end

  def identify_code
    identification_code = IdentificationCodes::VerifyUser.run!(
      social_user: social_user,
      phone_number: params[:phone_number],
      uuid: params[:uuid],
      code: params[:code]
    )

    if identification_code
      render json: { identification_successful: true }
    else
      render json: {
        identification_successful: false,
        errors: {
          message: I18n.t("booking_page.message.booking_code_failed_message")
        }
      }
    end
  end
end
