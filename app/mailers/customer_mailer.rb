class CustomerMailer < ApplicationMailer
  layout "shop_to_customer"

  def reservation_confirmation
    @reservation = params[:reservation]
    @shop = @reservation.shop
    @customer = params[:customer]

    mail(
      to: customer_email,
      subject: I18n.t("customer_mailer.reservation_confirmation.title", shop_name: @shop.display_name),
      locale: I18n.default_locale
    )
  end

  def reservation_reminder
    @reservation = params[:reservation]
    @shop = @reservation.shop
    @customer = params[:customer]

    mail(
      to: customer_email,
      subject: I18n.t("customer_mailer.reservation_reminder.title", shop_name: @shop.display_name),
      locale: I18n.default_locale
    )
  end
end
