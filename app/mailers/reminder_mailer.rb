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

  def daily_reservations_limit_by_admin_reminder(user)
    @user = user
    @plan_name = user.member_plan_name
    @total_reservations_limit = Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[user.permission_level]
    @total_reservations_count = user.total_reservations_count

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.daily_reservations_limit_by_admin_reminder.title")),
         locale: I18n.default_locale)
  end

  def daily_reservations_limit_by_staff_reminder(user, shop)
    @user = user
    @plan_name = user.member_plan_name
    @total_reservations_limit = Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[user.permission_level]
    @total_reservations_count = user.total_reservations_count
    @shop_name = shop.display_name

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.daily_reservations_limit_by_staff_reminder.title")),
         locale: I18n.default_locale)
  end

  def total_reservations_limit_by_admin_reminder(user)
    @user = user
    @plan_name = user.member_plan_name
    @today_reservations_count = user.today_reservations_count
    @total_reservations_limit = Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[user.permission_level]
    @total_reservations_count = user.total_reservations_count

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.total_reservations_limit_by_admin_reminder.title")),
         locale: I18n.default_locale)
  end

  def total_reservations_limit_by_staff_reminder(user, shop)
    @user = user
    @plan_name = user.member_plan_name
    @today_reservations_count = user.today_reservations_count
    @total_reservations_limit = Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[user.permission_level]
    @total_reservations_count = user.total_reservations_count
    @shop_name = shop.display_name

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.total_reservations_limit_by_staff_reminder.title")),
         locale: I18n.default_locale)
  end
end
