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

  def activate_staff_account(staff_account)
    @staff_account = staff_account
    @staff = @staff_account.staff
    @owner = @staff_account.owner

    shop_names = @staff.shops.pluck(:name)

    @shops_sentence = if shop_names.size == 0
                        ""
                      elsif shop_names.size == 1
                        shop_names.first
                      else
                        "#{shop_names.first} 他1つの店舗"
                      end

    mail(:to => staff_account.email,
         :subject => "#{@shops_sentence}にスタッフとして設定されました。")
  end

  def staff_deleted(staff)
    @admin = staff.user
    @staff = staff

    @reservations = Reservation.future.includes(:customers).joins(:reservation_staffs).where("reservation_staffs.staff_id = ?", staff.id).order("reservations.start_time")

    mail(:to => @admin.email,
         :subject => subject("削除されたスタッフが担当者になっている予約があります。"))
  end
end
