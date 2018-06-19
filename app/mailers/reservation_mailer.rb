require 'mailer_methods'

class ReservationMailer < ActionMailer::Base
  helper MailHelper
  default from: ENV["MAIL_FROM"]

  include MailerMethods

  layout 'mailer'

  def pending_summary(reservations, user)
    @reservations = reservations
    @user = user

    mail(:to => @user.email,
         :subject => subject("確認が必要な予約があります"))
  end
end
