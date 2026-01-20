# frozen_string_literal: true

require "message_encryptor"

# OmniAuth configuration for proper callback URL handling
OmniAuth.config.full_host = lambda do |env|
  # Use APP_HOST environment variable to set the correct host for callbacks
  # This is especially important for staging/production environments
  scheme = env['rack.url_scheme']
  host = ENV['HEROKU_APP_DEFAULT_DOMAIN_NAME'] || env['HTTP_HOST']
  "#{scheme}://#{host}"
end

# Middleware to dynamically set LINE OAuth credentials per request
class DynamicLineOAuthMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    
    # Only process LINE OAuth requests
    if env['PATH_INFO'] =~ /^\/users\/auth\/line/
      oauth_social_account_id = request.params['oauth_social_account_id']
      
      if oauth_social_account_id.present?
        begin
          account_id = MessageEncryptor.decrypt(oauth_social_account_id)
          social_account = SocialAccount.find(account_id)
          
          # Find the LINE strategy in OmniAuth
          if strategy = env['omniauth.strategy']
            if strategy.is_a?(OmniAuth::Strategies::Line)
              # Dynamically set credentials for this request
              strategy.options[:client_id] = social_account.login_channel_id
              strategy.options[:client_secret] = social_account.raw_login_channel_secret
              
              Rails.logger.info("[DynamicLineOAuth] Set credentials for SocialAccount #{account_id}")
            end
          end
        rescue => e
          Rails.logger.error("[DynamicLineOAuth] Error: #{e.message}")
        end
      end
    end
    
    @app.call(env)
  end
end

Rails.application.config.middleware.use DynamicLineOAuthMiddleware
