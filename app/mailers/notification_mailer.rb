class NotificationMailer < ApplicationMailer
  def customers_import_finished(contact_group)
    @contact_group = contact_group
    @user = contact_group.user

    mail(:to => @user.email,
         :subject => subject("顧客台帳のGoogle同期作業が完了しました。"))
  end

  def customers_printing_finished(filtered_outcome)
    @filtered_outcome = filtered_outcome
    @user = filtered_outcome.user

    mail(:to => @user.email,
         :subject => subject("宛名印刷用ファイルの準備ができました。"))
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
         :subject => subject("#{@owner.name} の店舗にスタッフとして設定されました。"))
  end

  def staff_deleted(staff)
    @admin = staff.user
    @staff = staff

    @reservations = Reservation.future.active.includes(:customers).joins(:reservation_staffs).where("reservation_staffs.staff_id = ?", staff.id).order("reservations.start_time")

    mail(:to => @admin.email,
         :subject => subject("スタッフが削除されました。"))
  end

  def duplicate_customers(booking_page, customers, booking_customer, phone_number)
    @booking_page = booking_page
    @user = booking_page.user
    @customers = customers
    @booking_customer = booking_customer
    @phone_number = phone_number

    mail(:to => @user.email,
         subject: subject(I18n.t("notification_mailer.duplicate_customers.title")),
         locale: I18n.default_locale)
  end

  def new_referrer(referrer)
    @referee = referrer.reference.referee

    mail(:to => @referee.email,
         subject: subject(I18n.t("notification_mailer.new_referrer.title")),
         locale: I18n.default_locale)
  end
end
