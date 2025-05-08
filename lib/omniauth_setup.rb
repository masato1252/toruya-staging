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
    @env['omniauth.strategy'].options.merge!(custom_credentials.merge(scope: "profile openid email"))
  end

  # Use the subdomain in the request to find the account with credentials
  def custom_credentials
    who = @request.parameters["who"].presence || @request.cookies["who"]
    Rollbar.info("LineLogin3", who: who ? MessageEncryptor.decrypt(who) : nil, oauth_social_account_id: @request.parameters["oauth_social_account_id"] || @request.cookies["oauth_social_account_id"])

    if who && MessageEncryptor.decrypt(who) == CallbacksController::TORUYA_USER
      {
        client_id: Rails.application.secrets[:ja][:toruya_line_login_id],
        client_secret: Rails.application.secrets[:ja][:toruya_line_login_secret]
      }
    elsif who && MessageEncryptor.decrypt(who) == CallbacksController::TW_TORUYA_USER
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
        Rollbar.error("Unexpected line callback", request: @request)
      end
    end
  end
end
