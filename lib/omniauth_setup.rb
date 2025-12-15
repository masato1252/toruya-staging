# frozen_string_literal: true

require "message_encryptor"

class OmniauthSetup
  # OmniAuth expects the class passed to setup to respond to the #call method.
  # env - Rack environment
  def self.call(env)
    new(env).setup
  end

  # Assign variables and create a request object for use later.
  # env - Rack environment
  def initialize(env)
    @env = env
    @request = ActionDispatch::Request.new(env)
  end

  # The main purpose of this method is to set the consumer key and secret.
  def setup
    credentials = custom_credentials
    
    Rails.logger.info("[OmniauthSetup] Setup called with credentials: client_id=#{credentials[:client_id].present? ? 'present' : 'nil'}")
    
    # Store credentials in session for callback phase
    if credentials[:client_id].present?
      @request.session[:line_oauth_credentials] = credentials
    end
    
    @env['omniauth.strategy'].options.merge!(credentials.merge(scope: "profile openid email"))
  end
  
  # Use the subdomain in the request to find the account with credentials
  def custom_credentials
    who = @request.parameters["whois"].presence || @request.cookies["whois"] || @request.session[:line_oauth_who]
    
    Rails.logger.info("[OmniauthSetup] Parameters whois: #{@request.parameters["whois"].present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup] Cookies whois: #{@request.cookies["whois"].present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup] Session line_oauth_who: #{@request.session[:line_oauth_who].present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup] Who value: #{who.present? ? 'present' : 'nil'}")
    
    # Check if we have credentials in session from previous request phase
    if @request.session[:line_oauth_credentials].present?
      Rails.logger.info("[OmniauthSetup] Using credentials from session")
      return @request.session[:line_oauth_credentials]
    end
    
    # Store who in session for callback phase
    if who.present?
      @request.session[:line_oauth_who] = who
    end

    if who && MessageEncryptor.decrypt(who) == CallbacksController::TORUYA_USER
      Rails.logger.info("[OmniauthSetup] Using TORUYA_USER credentials")
      {
        client_id: Rails.application.secrets[:ja][:toruya_line_login_id],
        client_secret: Rails.application.secrets[:ja][:toruya_line_login_secret]
      }
    elsif who && MessageEncryptor.decrypt(who) == CallbacksController::TW_TORUYA_USER
      Rails.logger.info("[OmniauthSetup] Using TW_TORUYA_USER credentials")
      {
        client_id: Rails.application.secrets[:tw][:toruya_line_login_id],
        client_secret: Rails.application.secrets[:tw][:toruya_line_login_secret]
      }
    else
      oauth_social_account_id = @request.parameters["oauth_social_account_id"].presence || @request.cookies["oauth_social_account_id"]

      if oauth_social_account_id
        account = SocialAccount.find(MessageEncryptor.decrypt(oauth_social_account_id))

        {
          client_id: account.login_channel_id,
          client_secret: account.raw_login_channel_secret
        }
      else
        Rails.logger.error("[OmniauthSetup] No credentials found - who: #{who.inspect}, oauth_social_account_id: #{oauth_social_account_id.inspect}")
        Rollbar.error("Unexpected line callback", request: @request, who: who, cookies: @request.cookies.to_h.keys, session_keys: @request.session.to_h.keys)
        {}
      end
    end
  end
end
