# frozen_string_literal: true

Raven.configure do |config|
  config.dsn = 'https://1f1878d7ca5c40cfb37d1f368689fe2b:3310b1749c7747cd921cb8d229ff6325@sentry.io/1247637'
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
end
