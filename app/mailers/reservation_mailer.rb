require 'mailer_methods'

class ReservationMailer < ActionMailer::Base
  helper MailHelper
  default from: ENV["MAIL_FROM"]

  include MailerMethods

  layout 'mailer'

  def pending(reservation, staff)
    @reservation = reservation
    @staff = staff
    @user = staff.staff_account.user
    @by_staff = reservation.by_staff

    mail(:to => @user.email,
         :subject => subject("確認が必要な予約があります"))
  end

  def summary_pending(reservations, user)
  end
end
