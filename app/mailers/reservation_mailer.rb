# frozen_string_literal: true

class ReservationMailer < ApplicationMailer
  def pending_summary(reservations, user, message)
    @user = user
    @message = message

    mail(
      :to => @user.email,
      :subject => subject(I18n.t("mailers.pending_reservations_summary.title")),
      :body => @message
    )
  end
end
