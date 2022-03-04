# frozen_string_literal: true

source "http://rubygems.org"

ruby "2.6.6"

gem "rails", "~> 6.0"
gem "pg", "~> 1.1.4"
gem "pghero", "~> 2.8.1"
gem "pg_query", "~> 1.1.0"
gem "uglifier", ">= 1.3.0"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem "therubyracer", platforms: :ruby

gem "jbuilder"
# Use ActiveModel has_secure_password
# gem "bcrypt", "~> 3.1.7"
gem "sprockets", ">= 3.7.2"
gem "sass-rails", "~> 6"
gem "dotenv-rails", "~> 2.7.6", :require => "dotenv/rails-now"
gem "devise", "~> 4.8"
gem "omniauth-google-oauth2", "~> 0.7.0"
gem "omniauth-rails_csrf_protection"
gem "omniauth-line"
gem "omniauth-stripe-connect"
gem "react-rails"
gem "webpacker", "~> 4.2"
gem "active_link_to"
gem "aasm", "~> 4.11.0"
gem "active_interaction"
gem "holidays", "~> 8.4.1"
gem "default_value_for", "~> 3.4"
gem "week_of_month"
gem "nokogiri"
gem "google_contacts_api", git: "https://github.com/ilake/google_contacts_api.git"
gem "delayed_job_active_record", "~> 4.1.6"
gem "jp_prefecture", git: "https://github.com/ilake/jp_prefecture.git"
gem "hashie", "~> 3.4.4"
gem "rollbar", "~> 2.27.0"
gem "sendgrid-actionmailer"
gem "delayed-web"
gem "puma", "~> 4.3.3"
gem "kaminari"
gem "custom_error_message", "~> 1.2.1", git: "https://github.com/thethanghn/custom-err-msg.git"
gem "cancancan", "~> 1.15.0"
gem "wicked_pdf"
gem "wkhtmltopdf-binary"
gem "carrierwave"
gem "fog-aws", "~> 3.5.2"
gem "aws-sdk-s3" # for activestorage
gem "image_processing", "~> 1.2"
gem "bitly", "~> 1.0.0"
gem "lograge"
gem "stripe"
gem "money-rails", "~> 1.11.0"
gem "paper_trail"
gem "sentry-raven"
gem "slack-ruby-client"
gem "bootsnap"
gem "parallel"
gem "active_attr"
gem "twilio-ruby", "~> 5.25.1"
gem "phonelib"
gem "line-bot-api"
gem "oj"
gem "redis"
gem "jsonapi-serializer"
gem "serviceworker-rails"
gem "webpush", require: false
gem "js-routes"
gem "i18n-js"
gem "platform-api"
gem "skylight"
gem "newrelic_rpm"
gem "scout_apm"
gem "mixpanel-ruby"
gem "video_thumb"
gem "strong_migrations"
gem "ahoy_matey"
gem "with_advisory_lock"
gem 'acts-as-taggable-on', '~> 7.0'

group :development, :test do
  gem "byebug", platform: :mri
  gem "rspec-rails"
  gem "timecop", "~> 0.8.0"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem 'pry-byebug'
end

group :development do
  gem "listen"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "annotate", "~> 3.1.1"
  gem "letter_opener", "~> 1.4.1"
  gem "better_errors"
  gem "binding_of_caller"
  gem "bullet"
  gem "awesome_rails_console"
  gem "derailed_benchmarks"
  gem "rack-mini-profiler"
  gem "stackprof"
  gem "memory_profiler"
  gem "benchmark-memory"
  gem "magic_frozen_string_literal"
end

group :test do
  gem "stripe-ruby-mock", "~> 3.1.0.rc3", github: "stripe-ruby-mock/stripe-ruby-mock", require: "stripe_mock"
  gem "faker", git: "https://github.com/stympy/faker.git", branch: "master"
  gem "rspec_junit_formatter"
end

group :production do
  gem "dalli"
end
