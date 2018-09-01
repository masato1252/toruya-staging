class ReminderMailer < ApplicationMailer
  def trial_member_months_ago_reminder(user, the_rest_of_months)
    @user = user
    @the_rest_of_months = the_rest_of_months
    @signup_date = user.created_at.to_date
    @trial_expired_date = user.trial_expired_date

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.trial_member_months_ago_reminder.title")),
         locale: I18n.default_locale)
  end

  def trial_member_week_ago_reminder(user)
    @user = user
    @signup_date = user.created_at.to_date
    @trial_expired_date = user.trial_expired_date

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.trial_member_week_ago_reminder.title")),
         locale: I18n.default_locale)
  end

  def trial_member_day_ago_reminder(user)
    @user = user
    @signup_date = user.created_at.to_date
    @trial_expired_date = user.trial_expired_date

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.trial_member_day_ago_reminder.title")),
         locale: I18n.default_locale)
  end
end
