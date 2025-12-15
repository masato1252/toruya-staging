# frozen_string_literal: true

# OmniAuth configuration for proper callback URL handling
OmniAuth.config.full_host = lambda do |env|
  # Use APP_HOST environment variable to set the correct host for callbacks
  # This is especially important for staging/production environments
  scheme = env['rack.url_scheme']
  host = ENV['HEROKU_APP_DEFAULT_DOMAIN_NAME'] || env['HTTP_HOST']
  "#{scheme}://#{host}"
end

