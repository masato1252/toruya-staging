class BookingMailer < ApplicationMailer
  layout false

  def customer_reservation_notification
    @reservation = params[:reservation]
    @shop = @reservation.shop
    @customer = params[:customer]
    @booking_page = params[:booking_page]
    @booking_option = params[:booking_option]

    tax_type = I18n.t("settings.booking_option.form.#{@booking_option.tax_include ? "tax_include" : "tax_excluded"}")
    @price = "#{@booking_option.amount.format(:ja_default_format)}(#{tax_type})"

    mail(
      to: params[:email],
      subject: subject(I18n.t("booking_mailer.customer_reservation_notification.title", shop_name: @shop.display_name)),
      locale: I18n.default_locale
    )
  end
end
