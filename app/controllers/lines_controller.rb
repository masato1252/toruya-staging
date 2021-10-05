# frozen_string_literal: true

require "message_encryptor"

class LinesController < ActionController::Base
  include ControllerHelpers

  protect_from_forgery with: :exception, prepend: true
  before_action :social_customer, only: %w(identify_shop_customer find_customer create_customer identify_code ask_identification_code)
  skip_before_action :track_ahoy_visit

  layout "booking"

  def identify_shop_customer; end

  def identify_code
    identification_code = Customers::VerifyIdentificationCode.run!(
      social_customer: social_customer,
      uuid: params[:uuid],
      code: params[:code]
    )

    if identification_code
      unless customer = Customers::Find.run!(
          user: social_customer.user,
          first_name: params[:customer_first_name],
          last_name: params[:customer_last_name],
          phone_number: params[:customer_phone_number]
      )[:found_customer]
        customer = Customers::Create.run!(
          user: social_customer.user,
          customer_last_name: params[:customer_last_name],
          customer_first_name: params[:customer_first_name],
          customer_phonetic_last_name: params[:customer_phonetic_last_name],
          customer_phonetic_first_name: params[:customer_phonetic_first_name],
          customer_phone_number: params[:customer_phone_number]
        )
      end

      ApplicationRecord.transaction do
        booking_code = BookingCode.find_by!(uuid: params[:uuid])
        booking_code.update!(customer_id: customer.id)
        SocialCustomers::ConnectWithCustomer.run!(social_customer: social_customer, customer: customer)
      end

      render json: {
        identification_successful: true,
        customer_id: customer.id
      }
    else
      render json: {
        identification_successful: false,
        errors: {
          message: I18n.t("booking_page.message.booking_code_failed_message")
        }
      }
    end
  end

  def ask_identification_code
    identification_code = IdentificationCodes::Create.run!(
      user: social_customer.user,
      customer: customer,
      phone_number: params[:customer_phone_number]
    )

    render json: {
      identification_code: {
        uuid: identification_code.uuid,
        customer_id: customer&.id,
      }
    }
  end

  def contacts
    social_customer
  end

  def make_contact
    outcome = SocialCustomers::Contact.run(
      social_customer: social_customer,
      content: params[:content],
      last_name: params[:last_name],
      first_name: params[:first_name]
    )

    render json: json_response(outcome)
  end

  def update_customer_address
    if social_customer.customer != customer
      head :unprocessable_entity
      return
    end

    Customers::UpdateAddress.run(customer: customer, address_details: params.permit!.to_h[:address_details])

    head :ok
  end

  private

  def social_customer
    @social_customer ||= SocialCustomer.find_by!(social_user_id: params[:social_service_user_id] || MessageEncryptor.decrypt(params[:encrypted_social_service_user_id]))
  end

  def customer
    @customer ||= Customer.find_by(id: params[:customer_id])
  end
end
