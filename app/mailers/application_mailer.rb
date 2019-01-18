require "mailer_methods"

class ApplicationMailer < ActionMailer::Base
  helper MailHelper
  default from: ENV["MAIL_FROM"]

  include MailerMethods

  layout 'mailer'
end
