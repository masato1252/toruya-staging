class SubscriptionMailer < ApplicationMailer
  def charge_successfully(subscription)
    @user = subscription.user

    mail(to: @user.email,
         subject: subject(I18n.t("subscription_mailer.charge_successfully.title")),
         locale: I18n.default_locale)
  end

  def charge_failed(subscription)
    @user = subscription.user
    @next_period = subscription.next_period
    @charging_plan = subscription.next_plan || subscription.plan
    @cost = @charging_plan.cost_with_currency.format

    mail(to: @user.email,
         subject: subject(I18n.t("subscription_mailer.charge_failed.title")),
         locale: I18n.default_locale)
  end

  def charge_reminder(subscription)
    @user = subscription.user
    @next_period = subscription.next_period
    @charging_plan = subscription.next_plan || subscription.plan
    @cost = @charging_plan.cost_with_currency.format

    mail(to: @user.email,
         subject: subject(I18n.t("subscription_mailer.charge_reminder.title")),
         locale: I18n.default_locale
        )
  end
end
