# frozen_string_literal: true

require "message_encryptor"

class Lines::CustomersController < ActionController::Base
  layout "booking"

  protect_from_forgery with: :exception, prepend: true
  abstract!

  include ControllerHelpers

  def current_customer
    current_social_customer&.customer
  end
  helper_method :current_customer

  def current_social_customer
    social_user_id = params[:encrypted_social_service_user_id] ? MessageEncryptor.decrypt(params[:encrypted_social_service_user_id]) : cookies[:line_social_user_id_of_customer]

    @current_social_customer ||= current_owner.social_customers.find_by(social_user_id: social_user_id)
  end
  helper_method :current_social_customer

  def current_owner
    raise NotImplementedError, "Subclass must implement this method"
  end
  helper_method :current_owner
end
