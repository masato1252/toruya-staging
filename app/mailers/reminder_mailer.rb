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

  def daily_reservations_limit_by_admin_reminder(user)
    @user = user
    @plan_name = I18n.t("plan.level.#{user.member_level}")
    @total_reservations_limit = Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[user.member_level]
    @total_reservations_count = Reservation.total_in_user(user)

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.daily_reservations_limit_by_admin_reminder.title")),
         locale: I18n.default_locale)
  end

  def daily_reservations_limit_by_staff_reminder(user, reservation)
    @user = user
    @plan_name = I18n.t("plan.level.#{user.member_level}")
    @total_reservations_limit = Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[user.member_level]
    @total_reservations_count = Reservation.total_in_user(user)
    @shop_name = reservation.shop.display_name

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.daily_reservations_limit_by_staff_reminder.title")),
         locale: I18n.default_locale)
  end

  def total_reservations_limit_by_admin_reminder(user)
    @user = user
    @plan_name = I18n.t("plan.level.#{user.member_level}")
    @today_reservations_count = Reservation.today_counts_in_user(user)
    @total_reservations_limit = Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[user.member_level]
    @total_reservations_count = Reservation.total_in_user(user)

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.total_reservations_limit_by_admin_reminder.title")),
         locale: I18n.default_locale)
  end

  def total_reservations_limit_by_staff_reminder(user, reservation)
    @user = user
    @plan_name = I18n.t("plan.level.#{user.member_level}")
    @today_reservations_count = Reservation.today_counts_in_user(user)
    @total_reservations_limit = Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[user.member_level]
    @total_reservations_count = Reservation.total_in_user(user)
    @shop_name = reservation.shop.display_name

    mail(to: @user.email,
         subject: subject(I18n.t("reminder_mailer.total_reservations_limit_by_staff_reminder.title")),
         locale: I18n.default_locale)
  end
end
