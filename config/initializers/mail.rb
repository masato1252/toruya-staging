# frozen_string_literal: true

ActionMailer::Base.register_interceptor(SendGrid::MailInterceptor)
ActionMailer::Base.default_url_options[:host] = ENV['MAIL_DOMAIN']
ActionMailer::Base.default_url_options[:protocol] = ENV['HTTP_PROTOCOL']
ActionMailer::Base.default :from => ENV['MAIL_FROM']

if ENV['SENDGRID_USERNAME'] && ENV['SENDGRID_PASSWORD'] && Rails.env.production?
  ActionMailer::Base.smtp_settings = {
    :address        => 'smtp.sendgrid.net',
    :port           => '465',
    :authentication => :plain,
    :user_name      => ENV['SENDGRID_USERNAME'],
    :password       => ENV['SENDGRID_PASSWORD'],
    :domain         => 'heroku.com',
    :enable_starttls_auto => true,
    :ssl => true
  }
  ActionMailer::Base.delivery_method = :smtp
end
