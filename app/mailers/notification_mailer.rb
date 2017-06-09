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
end
