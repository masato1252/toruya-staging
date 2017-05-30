require 'mailer_methods'

class NotificationMailer < ActionMailer::Base
  helper MailHelper
  default from: ENV["MAIL_FROM"]

  include MailerMethods

  layout 'mailer'

  def customers_import_finished(contact_group)
    @contact_group = contact_group

    mail(:to => contact_group.user.email,
         :subject => subject("顧客台帳のGoogle同期作業が完了しました。"))

  end

  def staff_deleted(staff)
    @admin = staff.user
    @staff = staff

    @reservations = Reservation.future.includes(:customers).joins(:reservation_staffs).where("reservation_staffs.staff_id = ?", staff.id).order("reservations.start_time")

    mail(:to => @admin.email,
         :subject => subject("削除されたスタッフが担当者になっている予約があります。"))
  end
end
