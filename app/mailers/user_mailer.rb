# frozen_string_literal: true

class UserMailer < ApplicationMailer
  layout false

  def custom
    mail(
      to: params[:email],
      subject: params[:subject],
      body: params[:message]
    )
  end
end