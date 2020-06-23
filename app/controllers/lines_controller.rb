class LinesController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  before_action :social_customer, only: %w(identify_shop_customer find_customer identify_code)

  layout "booking"

  def identify_shop_customer; end

  def find_customer
    customer = Customers::Find.run!(
      user: social_customer.user,
      first_name: params[:customer_first_name],
      last_name: params[:customer_last_name],
      phone_number: params[:customer_phone_number]
    )[:found_customer]

    if customer
      identification_code = Customers::CreateIdentificationCode.run!(
        customer: customer,
        phone_number: params[:customer_phone_number]
      )

      render json: {
        identification_code: {
          uuid: identification_code.uuid,
          customer_id: customer.id
        }
      }
    else
      render json: {
        errors: {
          message: I18n.t("booking_page.message.unfound_customer_html")
        }
      }
    end
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
      customer: customer,
      phone_number: params[:customer_phone_number]
    )

    render json: {
      identification_code: {
        uuid: identification_code.uuid,
        customer_id: customer.id,
      }
    }
  end

  private

  def social_customer
    @social_customer ||= SocialCustomer.find_by!(social_user_id: params[:social_user_id])
  end

  def customer
    @customer ||= Customer.find(params[:customer_id])
  end
end
