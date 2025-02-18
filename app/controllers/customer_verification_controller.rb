# frozen_string_literal: true

class CustomerVerificationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token, only: [:generate_verification_code, :verify_code, :create_or_update_customer]

  # Generate a verification code and send it via SMS
  def generate_verification_code
    # Validate phone number format
    if I18n.locale == :ja && (Phonelib.invalid_for_country?(params[:customer_phone_number], 'JP') && Phonelib.invalid?(params[:customer_phone_number]))
      Rollbar.error("Customer verification invalid phone number", phone_number: params[:customer_phone_number])
      render json: {
        errors: {
          message: I18n.t("errors.invalid_jp_phone_number")
        }
      }
      return
    end

    # Create identification code
    identification_code = IdentificationCodes::Create.run!(
      phone_number: params[:customer_phone_number],
      user: User.find(params[:user_id])
    )

    render json: {
      uuid: identification_code.uuid
    }
  end

  # Verify the code entered by the customer
  def verify_code
    # Attempt to verify the code
    identification_code = IdentificationCodes::Verify.run(
      uuid: params[:uuid],
      code: params[:code]
    )

    if identification_code.valid?
      render json: {
        verification_successful: true,
        uuid: params[:uuid]
      }
    else
      render json: {
        verification_successful: false,
        errors: {
          message: identification_code.errors.full_messages.to_sentence
        }
      }
    end
  end

  # Create or update a customer with verified information
  def create_or_update_customer
    # Find or create customer
    customer = Customers::FindOrCreateCustomer.run!(
      user: User.find(params[:user_id]),
      social_customer: SocialCustomer.find_by(social_user_id: params[:customer_social_user_id]),
      last_name: params[:customer_last_name],
      first_name: params[:customer_first_name],
      phonetic_last_name: params[:customer_phonetic_last_name],
      phonetic_first_name: params[:customer_phonetic_first_name],
      phone_number: params[:customer_phone_number],
      email: params[:customer_email]
    )

    # Update the identification code with the customer ID
    if params[:uuid].present?
      ApplicationRecord.transaction do
        booking_code = BookingCode.find_by!(uuid: params[:uuid])
        booking_code.update!(customer_id: customer.id)
      end
    end

    cookies.permanent[:verified_customer_id] = customer.id

    render json: {
      customer_id: customer.id,
      customer_info: {
        last_name: customer.last_name,
        first_name: customer.first_name,
        phone_number: customer.customer_phone_number,
        email: customer.customer_email
      }
    }
  end
end