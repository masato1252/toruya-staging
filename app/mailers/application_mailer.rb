require "mailer_methods"

class ApplicationMailer < ActionMailer::Base
  helper MailHelper
  default from: ENV["MAIL_FROM"]

  include MailerMethods

  layout 'mailer'

  private

  def user
    @user ||= params[:user]
  end

  def customer_email
    if Rails.configuration.x.env.staging?
      User::ADMIN_EMAIL
    else
      params[:email]
    end
  end
end
