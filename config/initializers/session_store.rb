# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

if Rails.env.production?
  # For production environments
  session_options = {
    key: '_kasaike_session',
    secure: true,  # Require HTTPS
    same_site: :none,  # Required for cross-site redirects from LINE
    httponly: true
  }
  
  # Only set domain if using a custom domain (not herokuapp.com)
  if ENV['HEROKU_APP_DEFAULT_DOMAIN_NAME'] && !ENV['HEROKU_APP_DEFAULT_DOMAIN_NAME'].include?('herokuapp.com')
    session_options[:domain] = :all
  end
  
  Rails.application.config.session_store :cookie_store, session_options
else
  Rails.application.config.session_store :cookie_store, key: '_kasaike_session'
end
