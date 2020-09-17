require "random_code"

module Customers
  class CreateIdentificationCode < ActiveInteraction::Base
    object :user
    object :customer, default: nil
    string :phone_number

    def execute
      ApplicationRecord.transaction do
        code = RandomCode.generate(6)

        booking_code = BookingCode.create!(
          customer_id: customer&.id,
          uuid: SecureRandom.uuid,
          code: code
        )

        message = I18n.t("customer.notifications.sms.confirmation_code", code: code)

        compose(
          Sms::Create,
          user: user,
          message: "#{message}\n#{I18n.t("customer.notifications.noreply")}",
          phone_number: phone_number
        )

        booking_code
      end
    end

    def create_customer
      customer = Customers::Create.run!(
        user: social_customer.user,
        customer_last_name: params[:customer_last_name],
        customer_first_name: params[:customer_first_name],
        customer_phonetic_last_name: params[:customer_phonetic_last_name],
        customer_phonetic_first_name: params[:customer_phonetic_first_name],
        customer_phone_number: params[:customer_phone_number],
        customer_email: params[:customer_email]
      )

      ApplicationRecord.transaction do
        booking_code = BookingCode.find_by!(uuid: params[:uuid])
        booking_code.update!(customer_id: customer.id)
        SocialCustomers::ConnectWithCustomer.run!(social_customer: social_customer, customer: customer)
      end

      render json: { customer_id: customer.id }
    end

    def identify_code
      identification_code = Customers::VerifyIdentificationCode.run!(
        social_customer: social_customer,
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

    def ask_identification_code
      identification_code = Customers::CreateIdentificationCode.run!(
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

    # private
    #
    # def social_customer
    #   @social_customer ||= SocialCustomer.find_by!(social_user_id: params[:social_user_id])
    # end
    #
    # def customer
    #   @customer ||= Customer.find_by(id: params[:customer_id])
    # end
  end
end
