# frozen_string_literal: true

class BookingMailer < CustomerMailer
  def customer_reservation_notification
    @reservation = params[:reservation]
    @shop = @reservation.shop
    @customer = params[:customer]
    @booking_page = params[:booking_page]
    @booking_options = params[:booking_options]

    tax_type = I18n.t("settings.booking_option.form.#{@booking_option.tax_include ? "tax_include" : "tax_excluded"}")
    if @shop.user.currency == "JPY"
      @price = "#{@booking_option.amount.format(:ja_default_format)}(#{tax_type})"
    else
      @price = "#{@booking_option.amount.format}(#{tax_type})"
    end

    mail(
      to: customer_email,
      subject: I18n.t("booking_page.booking_mailer.customer_reservation_notification.title", shop_name: @shop.display_name),
      locale: I18n.default_locale
    )
  end

  def shop_owner_reservation_booked_notification
    @booking_page = params[:booking_page]
    @booking_option = params[:booking_option]
    @customer = params[:customer]
    @reservation = params[:reservation]
    @reservation_customer = @reservation.reservation_customers.find_by(customer_id: @customer.id)
    @shop = @booking_page.shop
    @user = @shop.user

    mail(
      to: @user.email,
      subject: subject(I18n.t("booking_page.booking_mailer.shop_owner_reservation_booked_notification.title")),
      locale: I18n.default_locale,
      layout: "mailer"
    )
  end
end
