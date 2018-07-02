require 'mailer_methods'

class SubscriptionMailer < ApplicationMailer
  def charge_successfully(subscription)
    @user = subscription.user

    mail(:to => @user.email,
         :subject => subject("Toruyaご請求完了のご連絡"))
  end
end
