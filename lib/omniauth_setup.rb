# frozen_string_literal: true

require "message_encryptor"

class OmniauthSetup
  def self.call(env)
    new(env).setup
  end

  def initialize(env)
    @env = env
    @request = ActionDispatch::Request.new(env)
  end

  def setup
    credentials = custom_credentials

    client_id = credentials[:client_id] || credentials["client_id"]
    client_secret = credentials[:client_secret] || credentials["client_secret"]

    if client_id.present?
      @request.session[:line_oauth_credentials] = credentials
    end

    @env["omniauth.strategy"].options[:client_id] = client_id if client_id
    @env["omniauth.strategy"].options[:client_secret] = client_secret if client_secret
    @env["omniauth.strategy"].options[:scope] = "profile openid email"
  rescue => e
    Rails.logger.error("[OmniauthSetup] Error in setup: #{e.class} - #{e.message}")
    raise
  end

  def custom_credentials
    if @request.session[:line_oauth_credentials].present?
      Rails.logger.info("[OmniauthSetup] Using credentials from session (gateway)")
      return @request.session[:line_oauth_credentials]
    end

    is_callback_phase =
      @request.parameters["oauth_social_account_id"].blank? &&
      @request.parameters["whois"].blank? &&
      (@request.parameters["code"].present? || @request.path.include?("callback"))

    if is_callback_phase
      Rails.logger.error("[OmniauthSetup] Callback phase without session credentials")
      Rollbar.error("Unexpected line callback", request: @request, session_keys: @request.session.to_h.keys) if Rails.configuration.x.env.production?
      return {}
    end

    legacy_start_phase_credentials
  end

  private

  def legacy_start_phase_credentials
    oauth_social_account_id =
      @request.parameters["oauth_social_account_id"].presence ||
      @request.session[:oauth_social_account_id]

    who =
      @request.parameters["whois"].presence ||
      @request.session[:line_oauth_who]

    who_routing = @request.parameters["who"].presence || @request.session[:line_oauth_who_routing]

    if @request.parameters["whois"].present?
      @request.session.delete(:oauth_social_account_id)
      oauth_social_account_id = nil
    end

    if @request.parameters["oauth_social_account_id"].present?
      @request.session.delete(:line_oauth_who)
      @request.session.delete(:line_oauth_who_routing)
      who = nil
    end

    @request.session[:line_oauth_who] = who if who.present?
    @request.session[:line_oauth_who_routing] = who_routing if who_routing.present?
    @request.session[:oauth_social_account_id] = oauth_social_account_id if oauth_social_account_id.present?

    oauth_redirect_to_url = @request.parameters["oauth_redirect_to_url"].presence
    @request.session[:oauth_redirect_to_url] = oauth_redirect_to_url if oauth_redirect_to_url.present?

    %w[booking_option_ids booking_date booking_at staff_id customer_id].each do |key|
      @request.session["oauth_#{key}"] = @request.parameters[key] if @request.parameters[key].present?
    end

    if oauth_social_account_id.present?
      account_id = MessageEncryptor.decrypt(oauth_social_account_id)
      account = SocialAccount.find(account_id)
      return {
        client_id: account.login_channel_id,
        client_secret: account.raw_login_channel_secret
      }
    end

    if who.present?
      decrypted_who = MessageEncryptor.decrypt(who)
      if decrypted_who == CallbacksController::TORUYA_USER
        return {
          client_id: Rails.application.secrets[:ja][:toruya_line_login_id],
          client_secret: Rails.application.secrets[:ja][:toruya_line_login_secret]
        }
      elsif decrypted_who == CallbacksController::TW_TORUYA_USER
        return {
          client_id: Rails.application.secrets[:tw][:toruya_line_login_id],
          client_secret: Rails.application.secrets[:tw][:toruya_line_login_secret]
        }
      end
    end

    Rails.logger.error("[OmniauthSetup] No credentials found for legacy start phase")
    {}
  end
end
