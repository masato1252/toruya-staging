# frozen_string_literal: true

ActionMailer::Base.default_url_options[:host] = ENV['MAIL_DOMAIN']
ActionMailer::Base.default_url_options[:protocol] = ENV['HTTP_PROTOCOL']
ActionMailer::Base.default :from => ENV['MAIL_FROM']
