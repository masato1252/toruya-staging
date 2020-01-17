class AdminMailer < ApplicationMailer
  layout false

  def new_business_application
    mail(
      to: User::HARUKO_EMAIL,
      subject: subject(I18n.t("admin_mailer.new_business_application.title")),
      locale: I18n.default_locale
    )
  end
end
