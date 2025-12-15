# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

if Rails.env.production?
  # Use domain: :all for production to allow cookies across subdomains
  Rails.application.config.session_store :cookie_store, 
    key: '_kasaike_session',
    domain: :all,
    secure: true,  # Require HTTPS
    same_site: :lax  # Allow cookies to be sent on redirects from LINE
else
  Rails.application.config.session_store :cookie_store, key: '_kasaike_session'
end
