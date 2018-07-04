class SubscriptionMailer < ApplicationMailer
  def charge_successfully(subscription)
    @user = subscription.user

    mail(:to => @user.email,
         :subject => subject("Toruyaご請求完了のご連絡"))
  end

  def charge_reminder(subscription)
    @user = subscription.user
    @next_period = subscription.next_period
    @charging_plan = subscription.next_plan || subscription.plan
    @cost = @charging_plan.cost_with_currency.format

    mail(to: @user.email,
         subject: subject("Toruyaご請求のご連絡"),
         locale: I18n.default_locale
        )
  end
end
