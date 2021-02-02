# frozen_string_literal: true

class BusinessApplicationMailer < ApplicationMailer
  # TODO: MESSAGE TBD
  def applicant_applied
    mail(
      to: user.email,
      subject: subject(I18n.t("business_application_mailer.applicant_applied.title")),
      locale: I18n.default_locale
    )
  end

  # TODO: MESSAGE TBD
  def applicant_approved
    mail(
      to: user.email,
      subject: subject(I18n.t("business_application_mailer.applicant_approved.title")),
      locale: I18n.default_locale
    )
  end

  # TODO: MESSAGE TBD
  def applicant_rejected
    mail(
      to: user.email,
      subject: subject(I18n.t("business_application_mailer.applicant_rejected.title")),
      locale: I18n.default_locale
    )
  end

  # TODO: MESSAGE TBD
  def applicant_paid
    mail(
      to: user.email,
      subject: subject(I18n.t("business_application_mailer.applicant_paid.title")),
      locale: I18n.default_locale
    )
  end

  private

  def business_application
    @business_application = params[:business_application]
  end

  def user
    @user ||= business_application.user
  end
end
