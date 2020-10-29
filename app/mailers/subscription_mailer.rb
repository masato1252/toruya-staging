class SubscriptionMailer < ApplicationMailer
  def charge_successfully(user)
    @user = user

    mail(to: @user.email,
         subject: subject(I18n.t("subscription_mailer.charge_successfully.title")),
         locale: I18n.default_locale)
  end

  def charge_failed(subscription, charge)
    @user = subscription.user
    @next_period = subscription.next_period
    @charging_plan = subscription.next_plan || subscription.plan
    @cost = charge.amount.format

    mail(to: @user.email,
         subject: subject(I18n.t("subscription_mailer.charge_failed.title")),
         locale: I18n.default_locale)
  end

  def charge_shop_fee(subscription, charge)
    @user = subscription.user
    @charge = charge
    @next_period = subscription.next_period
    @charging_plan = subscription.next_plan || subscription.plan
    @cost = Plans::Price.run!(user: @user, plan: @charging_plan, with_shop_fee: true).format

    mail(to: @user.email,
         subject: subject(I18n.t("subscription_mailer.charge_shop_fee.title")),
         locale: I18n.default_locale)
  end

  def charge_reminder(subscription)
    @user = subscription.user
    @next_period = subscription.next_period
    @charging_plan = subscription.next_plan || subscription.plan
    @cost = Plans::Price.run!(user: @user, plan: @charging_plan, with_shop_fee: true).format

    mail(to: @user.email,
         subject: subject(I18n.t("subscription_mailer.charge_reminder.title")),
         locale: I18n.default_locale
        )
  end
end
