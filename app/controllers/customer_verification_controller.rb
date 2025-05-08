# frozen_string_literal: true

class CustomerVerificationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token, only: [:generate_verification_code, :verify_code, :create_or_update_customer]

  # Generate a verification code and send it via email
  def generate_verification_code
    # Create identification code
    identification_code = IdentificationCodes::Create.run!(
      email: params[:customer_email],
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
      user: User.find(params[:user_id]),
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

    cookies.clear_across_domains(:verified_customer_id)
    cookies.set_across_domains(:verified_customer_id, customer.id, expires: 20.years.from_now)


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