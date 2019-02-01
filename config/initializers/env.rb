Rails.application.configure do
  config.x.env = ENV["PRODUCTION_ENV"] ? ActiveSupport::StringInquirer.new(ENV["PRODUCTION_ENV"]) : Rails.env
end
