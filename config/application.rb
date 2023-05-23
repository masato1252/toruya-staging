# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kasaike
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.autoloader = :classic

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    Dotenv.overload Rails.root.join(".env.#{Rails.env}")
    config.i18n.default_locale = 'ja'
    config.i18n.locale = 'ja'
    config.time_zone = "Tokyo"
    config.active_job.queue_adapter = :delayed_job

    config.active_record.schema_format = :sql

    config.autoload_once_paths << Rails.root.join('app/job_serializers')
    config.autoload_paths << Rails.root.join('app/instruments')
  end
end
