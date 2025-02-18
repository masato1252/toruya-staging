# frozen_string_literal: true

require "message_encryptor"

class LinesController < ActionController::Base
  include ControllerHelpers
  include ProductLocale
  include UserBotCookies

  protect_from_forgery with: :exception, prepend: true
  before_action :social_customer, only: %w(identify_shop_customer find_customer create_customer identify_code ask_identification_code)
  before_action :authenticate_social_user, only: %w(user_login)
  skip_before_action :track_ahoy_visit

  layout "booking"

  # customer sign up page from Line
  def identify_shop_customer
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
    if customer && social_customer.customer != customer
      head :unprocessable_entity
      return
    end

    Customers::UpdateAddress.run(customer: social_customer.customer, address_details: params.permit!.to_h[:address_details])

    head :ok
  end

  def user_login
    if params[:locale] == "tw"
      render action: "tw_user_login", layout: "booking"
      return
    end

    render layout: "booking"
  end

  def user_logout
    delete_user_bot_cookies(:social_service_user_id)

    if params[:locale] == "tw"
      redirect_to "https://toruya.tw"
    else
      redirect_to "https://toruya.com"
    end
  end

  private

  def social_customer
    @social_customer ||= SocialCustomer.find_by(social_user_id: params[:social_service_user_id] || MessageEncryptor.decrypt(params[:encrypted_social_service_user_id]))
  rescue ActiveSupport::MessageVerifier::InvalidSignature
  end

  def customer
    @customer ||= Customer.find_by(id: params[:customer_id])
  end

  def product_social_user
    social_customer&.user&.social_user
  end

  def authenticate_social_user
    if user_bot_cookies(:social_service_user_id)
      @social_user ||= SocialUser.find_by!(social_service_user_id: user_bot_cookies(:social_service_user_id))
      redirect_to root_path
    end
  end
end
