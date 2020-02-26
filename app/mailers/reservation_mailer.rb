class ReservationMailer < ApplicationMailer
  def pending_summary(reservations, user)
    @reservations = reservations
    @user = user

    mail(:to => @user.email,
         :subject => subject("確認が必要な予約があります"))
  end

  def booked
    @customer = params[:customer]

    mail(:to => params[:email],
         :subject => "Reservation Booked")
  end
end
