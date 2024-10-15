# frozen_string_literal: true

require "message_encryptor"

class CustomerMailer < ApplicationMailer
  layout "shop_to_customer"

  def reservation_confirmation
    @reservation = params[:reservation]
    @shop = @reservation.shop
    @customer = params[:customer]
    @encrypted_data = MessageEncryptor.encrypt({shop_id: @shop.id, customer_id: @customer.id })
    @content = params[:content]

    mail(
      to: customer_email,
      subject: I18n.t("customer_mailer.reservation_confirmation.title", shop_name: @shop.display_name),
      body: @content
    )
  end

  def reservation_reminder
    @reservation = params[:reservation]
    @shop = @reservation.shop
    @customer = params[:customer]
    @content = params[:content]

    mail(
      to: customer_email,
      subject: I18n.t("customer_mailer.reservation_reminder.title", shop_name: @shop.display_name),
      body: @content
    )
  end
end
