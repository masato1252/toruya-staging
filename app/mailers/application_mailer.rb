# frozen_string_literal: true

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
    params[:email]
  end
end
