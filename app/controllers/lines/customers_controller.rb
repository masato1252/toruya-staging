# frozen_string_literal: true

require "message_encryptor"

class Lines::CustomersController < ActionController::Base
  layout "booking"
  include UserBotCookies

  protect_from_forgery with: :exception, prepend: true
  abstract!

  include ControllerHelpers

  private

  def current_customer
    if params[:encrypted_customer_id].present?
      _id = MessageEncryptor.decrypt(params[:encrypted_customer_id])
      cookies[:verified_customer_id] = {
        value: _id,
        domain: :all,
        expires: 20.years.from_now
      }
      current_owner.customers.find_by(id: _id)
    else
      current_social_customer&.customer || current_owner.customers.find_by(id: cookies[:verified_customer_id])
    end
  end
  helper_method :current_customer
  before_action :set_locale

  def current_social_customer
    social_user_id =
      if params[:encrypted_social_service_user_id].present?
        _id = MessageEncryptor.decrypt(params[:encrypted_social_service_user_id])
        cookies[:line_social_user_id_of_customer] = {
          value: _id,
          domain: :all,
          expires: 20.years.from_now
        }
        _id
      elsif params[:temp_encrypted_social_service_user_id].present?
        _id = MessageEncryptor.decrypt(params[:temp_encrypted_social_service_user_id])

        cookies[:temp_line_social_user_id_of_customer] = {
          value: _id,
          expires: 5.minutes
        }
        _id
      elsif params[:social_service_user_id].present?
        params[:social_service_user_id]
      else
        if cookies[:temp_line_social_user_id_of_customer].present?
          cookies[:temp_line_social_user_id_of_customer]
        else
          cookies[:line_social_user_id_of_customer]
        end
      end

    @current_social_customer ||= current_owner.social_customers.find_by(social_user_id: social_user_id)
  end
  helper_method :current_social_customer

  def current_owner
    raise NotImplementedError, "Subclass must implement this method"
  end
  helper_method :current_owner

  def current_toruya_social_user
    @current_toruya_social_user ||= SocialUser.find_by(social_service_user_id: user_bot_cookies(:social_service_user_id))
  end
  helper_method :current_toruya_social_user

  def device_detector
    @device_detector ||=
      begin
        Current.device_detector = DeviceDetector.new(request.user_agent)
      end
  end
  helper_method :device_detector

  def business_owner_id
    params[:business_owner_id].presence || Current.business_owner&.id
  end
  helper_method :business_owner_id

  def set_locale
    I18n.locale = current_owner.locale || cookies[:locale] || I18n.default_locale
    cookies[:locale] = {
      value: I18n.locale,
      domain: :all,
      expires: 20.years.from_now
    }
    Time.zone = ::LOCALE_TIME_ZONE[I18n.locale] || "Asia/Tokyo"
  end
end