ActionMailer::Base.default_url_options[:host] = ENV['MAIL_DOMAIN']
ActionMailer::Base.default :from => ENV['MAIL_FROM']
