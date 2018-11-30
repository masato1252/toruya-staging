source "https://rubygems.org"

ruby "2.4.2"

gem "rails", "~> 5.1.0"
gem "pg", "~> 0.21.0"
gem "uglifier", ">= 1.3.0"
gem "coffee-rails", "~> 4.2"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem "therubyracer", platforms: :ruby

gem "jquery-rails"
gem "jbuilder", "~> 2.5"
# Use ActiveModel has_secure_password
# gem "bcrypt", "~> 3.1.7"
gem "bootstrap-sass", "~> 3.3.6"
gem "sprockets", ">= 3.7.2"
gem "sass-rails", "~> 5.0.6"
gem "dotenv-rails", "~> 2.2.1", :require => "dotenv/rails-now"
gem "devise", "~> 4.3.0"
gem "omniauth-google-oauth2"
gem "react-rails", "~> 2.4.0"
gem "webpacker", "~> 3.5.3"
gem "font-awesome-rails", "~> 4.7.0"
gem "active_link_to", "~> 1.0.3"
gem "aasm", "~> 4.11.0"
gem "active_interaction", github: "AaronLasseigne/active_interaction", branch: "v4.0.0"
gem "holidays", "~> 4.5.0"
gem "default_value_for", "~> 3.0.0"
gem "week_of_month"
gem "nokogiri", "~> 1.8.1"
gem "google_contacts_api", "~> 0.2.4", github: "ilake/google_contacts_api"
gem "delayed_job_active_record", "~> 4.1.1"
gem "jp_prefecture", "~> 0.8.1", github: "ilake/jp_prefecture"
gem "hashie", "~> 3.4.4"
gem "rollbar", "~> 2.15.5"
gem "sendgrid-rails", "~> 3.1.0"
gem "delayed-web", "~> 0.4.2"
gem "puma", "~> 3.11.0"
gem "kaminari", "~> 1.0.1"
gem "expeditor", "~> 0.5.0"
gem "newrelic_rpm", "~> 3.18.0"
gem "custom_error_message", "~> 1.2.1", github: "thethanghn/custom-err-msg"
gem "cancancan", "~> 1.15.0"
gem "wicked_pdf", "~> 1.1.0"
gem "wkhtmltopdf-binary"
gem "carrierwave", "~> 1.1.0"
gem "fog-aws", "~> 1.4.0"
gem "bitly", "~> 1.0.0"
gem "lograge", "~> 0.6.0"
gem "stripe", "~> 3.15.0"
gem "money-rails", "~> 1.11.0"
gem "paper_trail", "~> 9.2.0"
gem "sentry-raven"

group :development, :test do
  gem "byebug", platform: :mri
  gem "rspec-rails", "~> 3.5.0"
  gem "timecop", "~> 0.8.0"
  gem "database_cleaner"
  gem "factory_bot_rails"
end

group :development do
  gem "xray-rails"
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem "web-console"
  gem "listen", "~> 3.0.5"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "annotate"
  gem "letter_opener", "~> 1.4.1"
  gem "better_errors"
  gem "binding_of_caller"
  gem "bullet", "~> 2.0.0"
  gem "awesome_rails_console", "~> 0.4.0"
end

group :test do
  gem "stripe-ruby-mock", "~> 2.5.4", require: "stripe_mock"
end
