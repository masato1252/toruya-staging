# frozen_string_literal: true

ActionMailer::Base.default_url_options[:host] = ENV['MAIL_DOMAIN'] || "toruya.test"
ActionMailer::Base.default_url_options[:protocol] = ENV['HTTP_PROTOCOL'] || "https"
ActionMailer::Base.default :from => ENV['MAIL_FROM']
