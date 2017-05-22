require 'mailer_methods'

class NotificationMailer < ActionMailer::Base
  default from: ENV["MAIL_FROM"]

  include MailerMethods

  layout 'mailer'

  def customers_import_finished(contact_group)
    @contact_group = contact_group

    mail(:to => contact_group.user.email,
         :subject => "Toruya顧客台帳のGoogle同期作業が完了しました。")
  end

  def activate_staff_account(staff_account)
    @staff_account = staff_account
    @staff = @staff_account.staff
    @owner = @staff_account.owner

    mail(:to => staff_account.email,
         :subject => "Toruya staff account connection")
  end
end
