source "http://rubygems.org"

# ruby "2.4.2"

gem "rails", "~> 5.2.2"
gem "pg", "~> 0.21.0"
gem "uglifier", ">= 1.3.0"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem "therubyracer", platforms: :ruby

gem "jbuilder"
# Use ActiveModel has_secure_password
# gem "bcrypt", "~> 3.1.7"
gem "sprockets", ">= 3.7.2"
gem "sass-rails"
gem "dotenv-rails", "~> 2.2.1", :require => "dotenv/rails-now"
gem "devise"
gem "omniauth-google-oauth2"
gem "react-rails"
gem "webpacker", "< 4"
gem "active_link_to"
gem "aasm", "~> 4.11.0"
gem "active_interaction", github: "AaronLasseigne/active_interaction", branch: "v4.0.0"
gem "holidays", "~> 4.5.0"
gem "default_value_for"
gem "week_of_month"
gem "nokogiri"
gem "google_contacts_api", "~> 0.2.11", github: "ilake/google_contacts_api"
gem "delayed_job_active_record"
gem "jp_prefecture", "~> 0.8.1", github: "ilake/jp_prefecture"
gem "hashie", "~> 3.4.4"
gem "rollbar", "~> 2.15.5"
gem "sendgrid-rails"
gem "delayed-web"
gem "puma", "~> 3.11.0"
gem "kaminari"
gem "expeditor", "~> 0.5.0"
gem "newrelic_rpm", "~> 3.18.0"
gem "custom_error_message", "~> 1.2.1", github: "thethanghn/custom-err-msg"
gem "cancancan", "~> 1.15.0"
gem "wicked_pdf"
gem "wkhtmltopdf-binary"
gem "carrierwave"
gem "fog-aws", "~> 1.4.0"
gem "bitly", "~> 1.0.0"
gem "lograge"
gem "stripe"
gem "money-rails", "~> 1.11.0"
gem "paper_trail"
gem "sentry-raven"
gem "slack-ruby-client"
gem "bootsnap"

group :development, :test do
  gem "byebug", platform: :mri
  gem "rspec-rails"
  gem "timecop", "~> 0.8.0"
  gem "database_cleaner"
  gem "factory_bot_rails"
end

group :development do
  gem "listen"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "annotate"
  gem "letter_opener", "~> 1.4.1"
  gem "better_errors"
  gem "binding_of_caller"
  gem "bullet"
  gem "awesome_rails_console"
end

group :test do
  gem "stripe-ruby-mock", "~> 2.5.4", require: "stripe_mock"
  gem "faker", git: "https://github.com/stympy/faker.git", branch: "master"
  gem "rspec_junit_formatter"
end
