# frozen_string_literal: true

source "http://rubygems.org"

ruby "3.1.3"

gem "rails", "~> 7.0.4"
gem "next_rails"
gem "pg", "~> 1.1.4"
gem "pghero", "~> 2.8.1"
gem "pg_query"
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
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"
gem "omniauth-line"
gem "omniauth-stripe-connect"
gem 'omniauth-square', :git => 'https://github.com/dja/omniauth-square.git'
gem "google_drive", "~> 3.0.4"
gem "react-rails"
gem "webpacker", "~> 4.2.2"
gem "active_link_to"
gem "aasm", "~> 4.11.0"
gem "active_interaction"
gem "holidays", "~> 8.4.1"
gem "default_value_for", github: "FooBarWidget/default_value_for", branch: "master"
gem 'square.rb'
gem "week_of_month"
gem "nokogiri"
# gem "google_contacts_api", git: "https://github.com/ilake/google_contacts_api.git"
gem "delayed_job_active_record", "~> 4.1.6"
gem "jp_prefecture", git: "https://github.com/ilake/jp_prefecture.git"
gem "hashie", "~> 3.4.4"
gem "rollbar"
gem "sendgrid-actionmailer"
gem "delayed-web"
gem "delayed_job_web"
gem "puma"
gem "kaminari"
gem "cancancan", "~> 1.15.0"
gem "wicked_pdf"
gem "carrierwave"
gem "fog-aws", "~> 3.5.2"
gem "aws-sdk-s3" # for activestorage
gem "image_processing", "~> 1.2"
gem "mini_magick"
gem "bitly", "~> 1.0.0"
gem "lograge"
gem "stripe"
gem "money-rails"
gem "paper_trail"
gem "bootsnap"
gem "parallel"
gem "active_attr"
gem "twilio-ruby"
gem "phonelib"
gem "line-bot-api"
gem "oj"
gem "jsonapi-serializer"
gem "serviceworker-rails"
gem "webpush", require: false
gem "js-routes", "~> 1.4.9"
gem "i18n-js", "~> 3.8.0"
gem "platform-api"
gem "mixpanel-ruby"
gem "video_thumb"
gem "strong_migrations"
gem "ahoy_matey"
gem "with_advisory_lock"
gem 'acts-as-taggable-on'
gem "blazer"
gem 'deep_cloneable', '~> 3.2.0'
gem 'redis', '4.1.3'
gem 'request_store'
gem "barnes"
# gem "rails-autoscale-web"
# gem "rails-autoscale-delayed_job"
gem 'rack-cors'
gem 'psych', '< 4' # https://stackoverflow.com/questions/71191685/visit-psych-nodes-alias-unknown-alias-default-psychbadalias
gem 'marginalia'
gem "rqrcode", "~> 2.0"
gem 'chunky_png'
gem 'pycall'
gem 'activerecord-typedstore'
gem 'clamby' # Malware scanning with ClamAV

group :development, :test do
  gem "byebug", platform: :mri
  gem "rspec-rails"
  gem "timecop"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem 'pry-byebug'
  gem 'wkhtmltopdf-binary-edge-alpine'
end

group :development do
  gem "listen"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "annotate"
  gem "letter_opener", "~> 1.7.0"
  gem "letter_opener_web", "~> 2.0"
  gem "better_errors"
  gem "binding_of_caller"
  gem "bullet"
  gem "awesome_rails_console"
  gem "derailed_benchmarks"
  gem "stackprof"
  gem "memory_profiler"
  gem "benchmark-memory"
  gem "magic_frozen_string_literal"
  gem 'active_record_query_trace'
end

group :test do
  gem "stripe-ruby-mock", github: "stripe-ruby-mock/stripe-ruby-mock", require: "stripe_mock"
  gem "faker", git: "https://github.com/stympy/faker.git", branch: "main"
  gem "rspec_junit_formatter"
end

group :production do
  gem "dalli"
end
