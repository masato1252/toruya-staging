# frozen_string_literal: true

class ReminderMailer < ApplicationMailer
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
