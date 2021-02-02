# frozen_string_literal: true

Rails.application.configure do
  config.x.env = ENV["PRODUCTION_ENV"] ? ActiveSupport::StringInquirer.new(ENV["PRODUCTION_ENV"]) : Rails.env
end

Rails.application.routes.default_url_options[:host] = ENV['MAIL_DOMAIN']
Rails.application.routes.default_url_options[:protocol] = ENV['HTTP_PROTOCOL']
